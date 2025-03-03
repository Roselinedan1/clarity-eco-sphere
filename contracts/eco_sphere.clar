;; EcoSphere - Platform for eco-friendly businesses

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-rating (err u104))
(define-constant err-invalid-input (err u105))
(define-constant err-invalid-category (err u106))
(define-constant max-support-amount u1000000000) ;; 1000 STX maximum support

;; State Variables
(define-data-var next-business-id uint u1)
(define-data-var total-ratings-count uint u0)

;; Maps
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

(define-map user-ratings
    { user: principal, business-id: uint }
    { rating: uint }
)

(define-map verifications
    { verifier: principal, business-id: uint }
    { verified: bool, timestamp: uint }
)

;; Valid Categories
(define-data-var valid-categories (list 7 (string-ascii 20))
    (list "retail" "services" "manufacturing" "food & beverage" "energy" "transportation" "waste management")
)

;; Private Functions
(define-private (is-valid-category (category (string-ascii 20)))
    (fold and true (map (lambda (valid-cat) (is-eq category valid-cat)) (var-get valid-categories)))
)

(define-private (update-business-rating (business-id uint) (new-rating uint))
    (let (
        (business (unwrap! (map-get? businesses { business-id: business-id }) err-not-found))
        (current-count (get ratings-count business))
        (current-rating (get rating business))
        (new-count (+ current-count u1))
        (total-rating (+ (* current-rating current-count) new-rating))
        (new-avg-rating (/ (* total-rating u100) (* new-count u100)))
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

;; Public Functions
(define-public (register-business (name (string-ascii 50)) (description (string-ascii 500)) 
                                (eco-credentials (string-ascii 500)) (category (string-ascii 20)))
    (let (
        (business-id (var-get next-business-id))
    )
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len description) u0) err-invalid-input)
    (asserts! (> (len eco-credentials) u0) err-invalid-input)
    (asserts! (is-valid-category category) err-invalid-category)
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

[... rest of the contract remains unchanged ...]
