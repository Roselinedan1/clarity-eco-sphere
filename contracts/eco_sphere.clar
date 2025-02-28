;; EcoSphere - Platform for eco-friendly businesses

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-rating (err u104))
(define-constant err-invalid-input (err u105))
(define-constant max-support-amount u1000000000) ;; 1000 STX maximum support

;; Events
(define-data-var total-ratings-count uint u0)

;; Data Variables
(define-map businesses
    { business-id: uint }
    {
        owner: principal,
        name: (string-ascii 50),
        description: (string-ascii 500),
        eco-credentials: (string-ascii 500),
        category: (string-ascii 20),
        rating: uint,
        ratings-count: uint,
        verified: bool,
        total-support: uint,
        rewards-enabled: bool,
        reward-points: uint
    }
)

;; [Previous maps remain unchanged]

;; Private Functions
(define-private (update-business-rating (business-id uint) (new-rating uint))
    (let (
        (business (unwrap! (map-get? businesses { business-id: business-id }) err-not-found))
        (current-count (get ratings-count business))
        (current-rating (get rating business))
        (new-count (+ current-count u1))
        (new-avg-rating (/ (+ (* current-rating current-count) new-rating) new-count))
    )
    (map-set businesses
        { business-id: business-id }
        (merge business {
            rating: new-avg-rating,
            ratings-count: new-count
        })
    )
    (ok true))
)

;; [Previous private functions remain unchanged]

;; Public Functions
(define-public (register-business (name (string-ascii 50)) (description (string-ascii 500)) 
                                (eco-credentials (string-ascii 500)) (category (string-ascii 20)))
    (let (
        (business-id (var-get next-business-id))
    )
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len description) u0) err-invalid-input)
    (asserts! (> (len eco-credentials) u0) err-invalid-input)
    (asserts! (map-insert businesses
        { business-id: business-id }
        {
            owner: tx-sender,
            name: name,
            description: description,
            eco-credentials: eco-credentials,
            category: category,
            rating: u0,
            ratings-count: u0,
            verified: false,
            total-support: u0,
            rewards-enabled: false,
            reward-points: u0
        }
    ) err-already-exists)
    (var-set next-business-id (+ business-id u1))
    (print { type: "business-registered", business-id: business-id })
    (ok business-id))
)

(define-public (rate-business (business-id uint) (rating uint))
    (begin
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        (asserts! (map-insert user-ratings
            { user: tx-sender, business-id: business-id }
            { rating: rating }
        ) (err u105))
        (try! (update-business-rating business-id rating))
        (try! (award-points tx-sender business-id u10))
        (print { type: "business-rated", business-id: business-id, rating: rating })
        (ok true)
    )
)

(define-public (support-business (business-id uint) (amount uint))
    (let (
        (business (unwrap! (map-get? businesses { business-id: business-id }) err-not-found))
    )
    (begin
        (asserts! (<= amount max-support-amount) err-invalid-input)
        (try! (stx-transfer? amount tx-sender (get owner business)))
        (map-set businesses
            { business-id: business-id }
            (merge business { total-support: (+ (get total-support business) amount) })
        )
        (try! (award-points tx-sender business-id (/ amount u100)))
        (print { type: "business-supported", business-id: business-id, amount: amount })
        (ok true)
    ))
)

;; [Previous read-only functions remain unchanged with the addition of:]
(define-read-only (get-business-verification-count (business-id uint))
    (let ((count (len (filter verifications (lambda (verification)
        (and 
            (is-eq (get business-id verification) business-id)
            (get verified verification)
        )
    )))))
    (ok count))
)
