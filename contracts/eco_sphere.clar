;; EcoSphere - Platform for eco-friendly businesses

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

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
    { user: principal, business-id: uint }
    { verified: bool }
)

(define-map user-rewards
    { user: principal, business-id: uint }
    { points: uint }
)

(define-data-var next-business-id uint u1)

;; Private Functions
(define-private (is-business-owner (business-id uint) (caller principal))
    (let ((business (unwrap! (map-get? businesses { business-id: business-id }) err-not-found)))
        (is-eq (get owner business) caller)
    )
)

(define-private (award-points (user principal) (business-id uint) (amount uint))
    (let (
        (business (unwrap! (map-get? businesses { business-id: business-id }) err-not-found))
        (current-points (default-to u0 (get points (map-get? user-rewards { user: user, business-id: business-id }))))
    )
    (if (get rewards-enabled business)
        (begin
            (map-set user-rewards
                { user: user, business-id: business-id }
                { points: (+ current-points amount) }
            )
            (ok true)
        )
        (ok false)
    ))
)

;; Public Functions
(define-public (register-business (name (string-ascii 50)) (description (string-ascii 500)) 
                                (eco-credentials (string-ascii 500)) (category (string-ascii 20)))
    (let (
        (business-id (var-get next-business-id))
    )
    (asserts! (map-insert businesses
        { business-id: business-id }
        {
            owner: tx-sender,
            name: name,
            description: description,
            eco-credentials: eco-credentials,
            category: category,
            rating: u0,
            verified: false,
            total-support: u0,
            rewards-enabled: false,
            reward-points: u0
        }
    ) err-already-exists)
    (var-set next-business-id (+ business-id u1))
    (ok business-id))
)

(define-public (enable-rewards (business-id uint))
    (let ((business (unwrap! (map-get? businesses { business-id: business-id }) err-not-found)))
        (asserts! (is-business-owner business-id tx-sender) err-unauthorized)
        (map-set businesses
            { business-id: business-id }
            (merge business { rewards-enabled: true })
        )
        (ok true)
    )
)

(define-public (rate-business (business-id uint) (rating uint))
    (begin
        (asserts! (<= rating u5) (err u104))
        (asserts! (map-insert user-ratings
            { user: tx-sender, business-id: business-id }
            { rating: rating }
        ) (err u105))
        (try! (award-points tx-sender business-id u10))
        (ok true)
    )
)

(define-public (verify-business (business-id uint))
    (begin
        (asserts! (is-some (map-get? businesses { business-id: business-id })) err-not-found)
        (map-set verifications
            { user: tx-sender, business-id: business-id }
            { verified: true }
        )
        (try! (award-points tx-sender business-id u50))
        (ok true)
    )
)

(define-public (support-business (business-id uint) (amount uint))
    (let (
        (business (unwrap! (map-get? businesses { business-id: business-id }) err-not-found))
    )
    (begin
        (try! (stx-transfer? amount tx-sender (get owner business)))
        (map-set businesses
            { business-id: business-id }
            (merge business { total-support: (+ (get total-support business) amount) })
        )
        (try! (award-points tx-sender business-id (/ amount u100)))
        (ok true)
    ))
)

;; Read-only Functions
(define-read-only (get-business (business-id uint))
    (ok (map-get? businesses { business-id: business-id }))
)

(define-read-only (get-business-rating (business-id uint))
    (ok (get rating (unwrap! (map-get? businesses { business-id: business-id }) err-not-found)))
)

(define-read-only (get-business-verification-count (business-id uint))
    (ok (len (map-get? verifications { business-id: business-id })))
)

(define-read-only (get-user-points (user principal) (business-id uint))
    (ok (default-to u0 (get points (map-get? user-rewards { user: user, business-id: business-id }))))
)

(define-read-only (get-businesses-by-category (category (string-ascii 20)))
    (filter businesses (lambda (business)
        (is-eq (get category business) category)
    ))
)
