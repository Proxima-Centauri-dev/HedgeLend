
;; title: HedgeLend
;; version: 1.0.0
;; summary: DeFi lending protocol with hedge fund strategies and sophisticated risk management
;; description: A lending protocol that implements dynamic interest rates, risk-adjusted pricing, and advanced liquidation mechanisms

;; ========================================
;; CONSTANTS
;; ========================================

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_AUTHORIZED (err u101))
(define-constant ERR_INSUFFICIENT_FUNDS (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_INSUFFICIENT_COLLATERAL (err u104))
(define-constant ERR_POSITION_UNHEALTHY (err u105))
(define-constant ERR_LIQUIDATION_NOT_ALLOWED (err u106))
(define-constant ERR_USER_NOT_FOUND (err u107))
(define-constant ERR_INVALID_PARAMETERS (err u108))
(define-constant ERR_POOL_SUSPENDED (err u109))

;; Risk management constants
(define-constant LIQUIDATION_THRESHOLD u8000) ;; 80% in basis points (10000 = 100%)
(define-constant LIQUIDATION_PENALTY u500)    ;; 5% liquidation penalty
(define-constant MAX_UTILIZATION_RATE u9000)  ;; 90% max utilization
(define-constant BASE_INTEREST_RATE u200)     ;; 2% base interest rate
(define-constant RISK_PREMIUM_MULTIPLIER u50) ;; Risk premium factor

;; Precision constants
(define-constant PRECISION u10000)
(define-constant SECONDS_IN_YEAR u31536000)

;; ========================================
;; DATA VARIABLES
;; ========================================

(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var emergency-shutdown bool false)
(define-data-var total-deposits uint u0)
(define-data-var total-borrowed uint u0)
(define-data-var protocol-fee uint u100) ;; 1% protocol fee

;; Interest rate model parameters
(define-data-var base-rate uint BASE_INTEREST_RATE)
(define-data-var utilization-rate uint u0)
(define-data-var last-update-height uint u0)

;; ========================================
;; DATA MAPS
;; ========================================

;; User account information
(define-map user-accounts
    principal
    {
        deposits: uint,
        borrowed: uint,
        collateral: uint,
        last-interaction-height: uint,
        health-factor: uint,
        accrued-interest: uint
    })

;; Lending pool information
(define-map lending-pools
    principal ;; asset identifier (using principal for simplicity)
    {
        total-supply: uint,
        total-borrowed: uint,
        interest-rate: uint,
        last-update: uint,
        reserve-factor: uint,
        active: bool
    })

;; Risk assessment data
(define-map risk-parameters
    principal
    {
        ltv-ratio: uint,        ;; Loan-to-Value ratio
        liquidation-threshold: uint,
        liquidation-penalty: uint,
        price-volatility: uint,
        risk-weight: uint
    })

;; Liquidation positions
(define-map liquidation-queue
    principal
    {
        user: principal,
        debt-amount: uint,
        collateral-amount: uint,
        liquidation-price: uint,
        timestamp: uint
    })

;; ========================================
;; PRIVATE FUNCTIONS
;; ========================================

(define-private (is-owner (user principal))
    (is-eq user (var-get contract-owner)))

(define-private (check-emergency-shutdown)
    (not (var-get emergency-shutdown)))

;; Calculate compound interest using simplified formula
(define-private (calculate-interest (principal-amount uint) (rate uint) (time-elapsed uint))
    (let ((interest-factor (/ (* rate time-elapsed) SECONDS_IN_YEAR)))
        (/ (* principal-amount interest-factor) PRECISION)))

;; Calculate health factor for a user position
(define-private (calculate-health-factor (user principal))
    (let ((account (default-to 
                    { deposits: u0, borrowed: u0, collateral: u0, 
                      last-interaction-height: u0, health-factor: PRECISION, accrued-interest: u0 }
                    (map-get? user-accounts user))))
        (if (is-eq (get borrowed account) u0)
            PRECISION ;; If no debt, health factor is maximum
            (/ (* (get collateral account) PRECISION) 
               (* (get borrowed account) LIQUIDATION_THRESHOLD)))))

;; Update user's accrued interest
(define-private (update-accrued-interest (user principal))
    (let ((account (default-to 
                    { deposits: u0, borrowed: u0, collateral: u0, 
                      last-interaction-height: u0, health-factor: PRECISION, accrued-interest: u0 }
                    (map-get? user-accounts user)))
          (current-height block-height)
          (time-elapsed (- current-height (get last-interaction-height account)))
          (current-rate (calculate-dynamic-interest-rate)))
        (if (> (get borrowed account) u0)
            (let ((new-interest (calculate-interest (get borrowed account) current-rate time-elapsed)))
                (map-set user-accounts user
                    (merge account { 
                        accrued-interest: (+ (get accrued-interest account) new-interest),
                        last-interaction-height: current-height 
                    })))
            true)))

;; Calculate dynamic interest rate based on utilization
(define-private (calculate-dynamic-interest-rate)
    (let ((utilization (calculate-utilization-rate))
          (current-base-rate (var-get base-rate)))
        (if (> utilization MAX_UTILIZATION_RATE)
            (+ current-base-rate (* RISK_PREMIUM_MULTIPLIER (/ utilization PRECISION)))
            (+ current-base-rate (/ (* utilization current-base-rate) PRECISION)))))

;; Calculate current utilization rate
(define-private (calculate-utilization-rate)
    (let ((current-deposits (var-get total-deposits))
          (current-borrowed (var-get total-borrowed)))
        (if (is-eq current-deposits u0)
            u0
            (/ (* current-borrowed PRECISION) current-deposits))))

;; Validate liquidation conditions
(define-private (can-liquidate (user principal))
    (let ((health-factor (calculate-health-factor user)))
        (< health-factor PRECISION)))

;; Helper function to get minimum of two values
(define-private (min-uint (a uint) (b uint))
    (if (<= a b) a b))

;; ========================================
;; PUBLIC FUNCTIONS
;; ========================================

;; Initialize or update risk parameters for an asset
(define-public (set-risk-parameters (asset principal) 
                                   (ltv-ratio uint) 
                                   (liquidation-threshold uint) 
                                   (liquidation-penalty uint)
                                   (price-volatility uint)
                                   (risk-weight uint))
    (begin
        (asserts! (is-owner tx-sender) ERR_OWNER_ONLY)
        (asserts! (and (<= ltv-ratio PRECISION) 
                      (<= liquidation-threshold PRECISION) 
                      (<= liquidation-penalty PRECISION)
                      (<= risk-weight PRECISION)) ERR_INVALID_PARAMETERS)
        (map-set risk-parameters asset {
            ltv-ratio: ltv-ratio,
            liquidation-threshold: liquidation-threshold,
            liquidation-penalty: liquidation-penalty,
            price-volatility: price-volatility,
            risk-weight: risk-weight
        })
        (ok true)))

;; Deposit STX to the lending pool
(define-public (deposit (amount uint))
    (begin
        (asserts! (check-emergency-shutdown) ERR_POOL_SUSPENDED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update user account
        (let ((current-account (default-to 
                               { deposits: u0, borrowed: u0, collateral: u0, 
                                 last-interaction-height: block-height, health-factor: PRECISION, accrued-interest: u0 }
                               (map-get? user-accounts tx-sender))))
            (map-set user-accounts tx-sender
                (merge current-account { 
                    deposits: (+ (get deposits current-account) amount),
                    last-interaction-height: block-height
                })))
        
        ;; Update global state
        (var-set total-deposits (+ (var-get total-deposits) amount))
        (var-set last-update-height block-height)
        (ok amount)))

;; Withdraw STX from deposits
(define-public (withdraw (amount uint))
    (begin
        (asserts! (check-emergency-shutdown) ERR_POOL_SUSPENDED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        
        (let ((current-account (unwrap! (map-get? user-accounts tx-sender) ERR_USER_NOT_FOUND)))
            (asserts! (>= (get deposits current-account) amount) ERR_INSUFFICIENT_FUNDS)
            
            ;; Update user account
            (map-set user-accounts tx-sender
                (merge current-account { 
                    deposits: (- (get deposits current-account) amount),
                    last-interaction-height: block-height
                }))
            
            ;; Update global state
            (var-set total-deposits (- (var-get total-deposits) amount))
            (var-set last-update-height block-height)
            
            ;; Transfer STX back to user
            (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
            (ok amount))))

;; Borrow against collateral
(define-public (borrow (amount uint))
    (begin
        (asserts! (check-emergency-shutdown) ERR_POOL_SUSPENDED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        
        (let ((current-account (unwrap! (map-get? user-accounts tx-sender) ERR_USER_NOT_FOUND)))
            ;; Check if user has sufficient collateral
            (asserts! (> (get collateral current-account) u0) ERR_INSUFFICIENT_COLLATERAL)
            
            ;; Calculate max borrowable amount (simplified LTV check)
            (let ((max-borrow (/ (* (get collateral current-account) LIQUIDATION_THRESHOLD) PRECISION)))
                (asserts! (<= (+ (get borrowed current-account) amount) max-borrow) ERR_INSUFFICIENT_COLLATERAL)
                
                ;; Update user account
                (update-accrued-interest tx-sender)
                (map-set user-accounts tx-sender
                    (merge current-account { 
                        borrowed: (+ (get borrowed current-account) amount),
                        last-interaction-height: block-height,
                        health-factor: (calculate-health-factor tx-sender)
                    }))
                
                ;; Update global state
                (var-set total-borrowed (+ (var-get total-borrowed) amount))
                
                ;; Transfer STX to borrower
                (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
                (ok amount)))))

;; Add collateral to user account
(define-public (add-collateral (amount uint))
    (begin
        (asserts! (check-emergency-shutdown) ERR_POOL_SUSPENDED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (let ((current-account (default-to 
                               { deposits: u0, borrowed: u0, collateral: u0, 
                                 last-interaction-height: block-height, health-factor: PRECISION, accrued-interest: u0 }
                               (map-get? user-accounts tx-sender))))
            (map-set user-accounts tx-sender
                (merge current-account { 
                    collateral: (+ (get collateral current-account) amount),
                    last-interaction-height: block-height,
                    health-factor: (calculate-health-factor tx-sender)
                }))
            (ok amount))))

;; Repay borrowed amount
(define-public (repay (amount uint))
    (begin
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        
        (let ((current-account (unwrap! (map-get? user-accounts tx-sender) ERR_USER_NOT_FOUND)))
            (asserts! (> (get borrowed current-account) u0) ERR_INVALID_AMOUNT)
            
            ;; Update accrued interest first
            (update-accrued-interest tx-sender)
            
            (let ((total-debt (+ (get borrowed current-account) (get accrued-interest current-account)))
                  (repay-amount (if (<= amount total-debt) amount total-debt)))
                
                (try! (stx-transfer? repay-amount tx-sender (as-contract tx-sender)))
                
                ;; Update user account
                (map-set user-accounts tx-sender
                    (merge current-account { 
                        borrowed: (if (>= repay-amount total-debt) u0 (- total-debt repay-amount)),
                        accrued-interest: u0,
                        last-interaction-height: block-height,
                        health-factor: (calculate-health-factor tx-sender)
                    }))
                
                ;; Update global state
                (var-set total-borrowed (- (var-get total-borrowed) (min-uint amount (get borrowed current-account))))
                (ok repay-amount)))))

;; Liquidate an undercollateralized position
(define-public (liquidate (user principal) (debt-to-cover uint))
    (begin
        (asserts! (check-emergency-shutdown) ERR_POOL_SUSPENDED)
        (asserts! (> debt-to-cover u0) ERR_INVALID_AMOUNT)
        (asserts! (can-liquidate user) ERR_LIQUIDATION_NOT_ALLOWED)
        
        (let ((user-account (unwrap! (map-get? user-accounts user) ERR_USER_NOT_FOUND)))
            ;; Update interest before liquidation
            (update-accrued-interest user)
            
            (let ((total-debt (+ (get borrowed user-account) (get accrued-interest user-account)))
                  (liquidation-amount (min-uint debt-to-cover total-debt))
                  (collateral-to-seize (+ (/ (* liquidation-amount PRECISION) LIQUIDATION_THRESHOLD)
                                        (/ (* liquidation-amount LIQUIDATION_PENALTY) PRECISION))))
                
                ;; Transfer debt payment from liquidator
                (try! (stx-transfer? liquidation-amount tx-sender (as-contract tx-sender)))
                
                ;; Transfer collateral to liquidator
                (try! (as-contract (stx-transfer? collateral-to-seize tx-sender tx-sender)))
                
                ;; Update user account
                (map-set user-accounts user
                    (merge user-account { 
                        borrowed: (- total-debt liquidation-amount),
                        collateral: (- (get collateral user-account) collateral-to-seize),
                        accrued-interest: u0,
                        last-interaction-height: block-height,
                        health-factor: (calculate-health-factor user)
                    }))
                
                ;; Update global state
                (var-set total-borrowed (- (var-get total-borrowed) liquidation-amount))
                (ok { liquidated-debt: liquidation-amount, seized-collateral: collateral-to-seize })))))

;; Emergency functions
(define-public (toggle-emergency-shutdown)
    (begin
        (asserts! (is-owner tx-sender) ERR_OWNER_ONLY)
        (var-set emergency-shutdown (not (var-get emergency-shutdown)))
        (ok (var-get emergency-shutdown))))

(define-public (update-contract-owner (new-owner principal))
    (begin
        (asserts! (is-owner tx-sender) ERR_OWNER_ONLY)
        (var-set contract-owner new-owner)
        (ok true)))

;; ========================================
;; READ-ONLY FUNCTIONS
;; ========================================

(define-read-only (get-user-account (user principal))
    (map-get? user-accounts user))

(define-read-only (get-user-health-factor (user principal))
    (calculate-health-factor user))

(define-read-only (get-current-interest-rate)
    (calculate-dynamic-interest-rate))

(define-read-only (get-utilization-rate)
    (calculate-utilization-rate))

(define-read-only (get-total-deposits)
    (var-get total-deposits))

(define-read-only (get-total-borrowed)
    (var-get total-borrowed))

(define-read-only (get-protocol-stats)
    {
        total-deposits: (var-get total-deposits),
        total-borrowed: (var-get total-borrowed),
        utilization-rate: (calculate-utilization-rate),
        current-interest-rate: (calculate-dynamic-interest-rate),
        emergency-shutdown: (var-get emergency-shutdown)
    })

(define-read-only (can-user-borrow (user principal) (amount uint))
    (match (map-get? user-accounts user)
        account (let ((max-borrow (/ (* (get collateral account) LIQUIDATION_THRESHOLD) PRECISION)))
                    (<= (+ (get borrowed account) amount) max-borrow))
        false))

(define-read-only (get-liquidation-threshold)
    LIQUIDATION_THRESHOLD)

(define-read-only (is-position-liquidatable (user principal))
    (can-liquidate user))
