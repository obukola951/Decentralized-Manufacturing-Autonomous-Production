;; Factory Verification Contract
;; Validates autonomous manufacturing facilities

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-FACTORY-EXISTS (err u101))
(define-constant ERR-FACTORY-NOT-FOUND (err u102))
(define-constant ERR-INVALID-STATUS (err u103))

(define-data-var contract-owner principal tx-sender)

(define-map factories
  { factory-id: uint }
  {
    owner: principal,
    location: (string-ascii 100),
    capacity: uint,
    status: (string-ascii 20),
    certification-level: uint,
    last-inspection: uint,
    verified: bool
  }
)

(define-data-var next-factory-id uint u1)

(define-public (register-factory (location (string-ascii 100)) (capacity uint))
  (let ((factory-id (var-get next-factory-id)))
    (asserts! (is-none (map-get? factories { factory-id: factory-id })) ERR-FACTORY-EXISTS)
    (map-set factories
      { factory-id: factory-id }
      {
        owner: tx-sender,
        location: location,
        capacity: capacity,
        status: "pending",
        certification-level: u0,
        last-inspection: block-height,
        verified: false
      }
    )
    (var-set next-factory-id (+ factory-id u1))
    (ok factory-id)
  )
)

(define-public (verify-factory (factory-id uint) (certification-level uint))
  (let ((factory (unwrap! (map-get? factories { factory-id: factory-id }) ERR-FACTORY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (map-set factories
      { factory-id: factory-id }
      (merge factory {
        status: "verified",
        certification-level: certification-level,
        last-inspection: block-height,
        verified: true
      })
    )
    (ok true)
  )
)

(define-public (update-factory-status (factory-id uint) (new-status (string-ascii 20)))
  (let ((factory (unwrap! (map-get? factories { factory-id: factory-id }) ERR-FACTORY-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner factory)) ERR-NOT-AUTHORIZED)
    (map-set factories
      { factory-id: factory-id }
      (merge factory { status: new-status })
    )
    (ok true)
  )
)

(define-read-only (get-factory (factory-id uint))
  (map-get? factories { factory-id: factory-id })
)

(define-read-only (is-factory-verified (factory-id uint))
  (match (map-get? factories { factory-id: factory-id })
    factory (get verified factory)
    false
  )
)
