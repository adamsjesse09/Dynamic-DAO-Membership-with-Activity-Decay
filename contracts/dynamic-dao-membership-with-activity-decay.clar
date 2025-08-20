(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_MEMBER (err u101))
(define-constant ERR_ALREADY_MEMBER (err u102))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u103))
(define-constant ERR_VOTING_ENDED (err u104))
(define-constant ERR_ALREADY_VOTED (err u105))
(define-constant ERR_INSUFFICIENT_VOTING_POWER (err u106))
(define-constant ERR_PROPOSAL_NOT_EXECUTABLE (err u107))

(define-constant DECAY_PERIOD u144)
(define-constant MIN_PROPOSAL_THRESHOLD u1000)
(define-constant VOTING_DURATION u1008)
(define-constant BASE_VOTING_POWER u1000)

(define-data-var next-member-id uint u1)
(define-data-var next-proposal-id uint u1)

(define-map members
  { member-id: uint }
  {
    address: principal,
    voting-power: uint,
    last-activity: uint,
    joined-at: uint,
    total-proposals: uint,
    total-votes: uint
  }
)

(define-map member-addresses
  { address: principal }
  { member-id: uint }
)

(define-map proposals
  {
    proposal-id: uint
  }
  {
    proposer: principal,
    title: (string-ascii 256),
    description: (string-ascii 1024),
    votes-for: uint,
    votes-against: uint,
    created-at: uint,
    voting-ends-at: uint,
    executed: bool,
    min-votes-required: uint
  }
)

(define-map proposal-votes
  { proposal-id: uint, voter: principal }
  { 
    vote: bool,
    voting-power-used: uint,
    voted-at: uint
  }
)

(define-public (join-dao)
  (let
    (
      (member-id (var-get next-member-id))
      (current-height stacks-block-height)
    )
    (asserts! (is-none (map-get? member-addresses { address: tx-sender })) ERR_ALREADY_MEMBER)
    
    (map-set members
      { member-id: member-id }
      {
        address: tx-sender,
        voting-power: BASE_VOTING_POWER,
        last-activity: current-height,
        joined-at: current-height,
        total-proposals: u0,
        total-votes: u0
      }
    )
    
    (map-set member-addresses
      { address: tx-sender }
      { member-id: member-id }
    )
    
    (var-set next-member-id (+ member-id u1))
    (ok member-id)
  )
)

(define-public (create-proposal (title (string-ascii 256)) (description (string-ascii 1024)))
  (let
    (
      (member-data (unwrap! (get-member-by-address tx-sender) ERR_NOT_MEMBER))
      (current-voting-power (get-current-voting-power tx-sender))
      (proposal-id (var-get next-proposal-id))
      (current-height stacks-block-height)
    )
    (asserts! (>= current-voting-power MIN_PROPOSAL_THRESHOLD) ERR_INSUFFICIENT_VOTING_POWER)
    
    (map-set proposals
      { proposal-id: proposal-id }
      {
        proposer: tx-sender,
        title: title,
        description: description,
        votes-for: u0,
        votes-against: u0,
        created-at: current-height,
        voting-ends-at: (+ current-height VOTING_DURATION),
        executed: false,
        min-votes-required: (/ (get-total-active-voting-power) u2)
      }
    )

    (unwrap! (update-member-activity tx-sender) (err u200))
    (unwrap! (update-member-proposals tx-sender) (err u201))
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
      (member-data (unwrap! (get-member-by-address tx-sender) ERR_NOT_MEMBER))
      (current-voting-power (get-current-voting-power tx-sender))
      (current-height stacks-block-height)
    )
    (asserts! (<= current-height (get voting-ends-at proposal)) ERR_VOTING_ENDED)
    (asserts! (is-none (map-get? proposal-votes { proposal-id: proposal-id, voter: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (> current-voting-power u0) ERR_INSUFFICIENT_VOTING_POWER)
    
    (map-set proposal-votes
      { proposal-id: proposal-id, voter: tx-sender }
      {
        vote: vote-for,
        voting-power-used: current-voting-power,
        voted-at: current-height
      }
    )
    
    (if vote-for
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-for: (+ (get votes-for proposal) current-voting-power) })
      )
      (map-set proposals
        { proposal-id: proposal-id }
        (merge proposal { votes-against: (+ (get votes-against proposal) current-voting-power) })
      )
    )
    
    (unwrap! (update-member-activity tx-sender) (err u202))
    (unwrap! (update-member-votes tx-sender) (err u203))
    (ok true)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let
    (
      (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
      (current-height stacks-block-height)
      (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
    )
    (asserts! (> current-height (get voting-ends-at proposal)) ERR_VOTING_ENDED)
    (asserts! (not (get executed proposal)) ERR_PROPOSAL_NOT_EXECUTABLE)
    (asserts! (>= total-votes (get min-votes-required proposal)) ERR_INSUFFICIENT_VOTING_POWER)
    (asserts! (> (get votes-for proposal) (get votes-against proposal)) ERR_PROPOSAL_NOT_EXECUTABLE)
    
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { executed: true })
    )
    
    (ok true)
  )
)

(define-public (refresh-membership)
  (let
    (
      (member-data (unwrap! (get-member-by-address tx-sender) ERR_NOT_MEMBER))
    )
    (unwrap! (update-member-activity tx-sender) (err u204))
    (ok true)
  )
)

(define-private (update-member-activity (member-address principal))
  (let
    (
      (member-info (unwrap! (map-get? member-addresses { address: member-address }) ERR_NOT_MEMBER))
      (member-data (unwrap! (map-get? members { member-id: (get member-id member-info) }) ERR_NOT_MEMBER))
      (current-height stacks-block-height)
    )
    (map-set members
      { member-id: (get member-id member-info) }
      (merge member-data { last-activity: current-height })
    )
    (ok true)
  )
)

(define-private (update-member-proposals (member-address principal))
  (let
    (
      (member-info (unwrap! (map-get? member-addresses { address: member-address }) ERR_NOT_MEMBER))
      (member-data (unwrap! (map-get? members { member-id: (get member-id member-info) }) ERR_NOT_MEMBER))
    )
    (map-set members
      { member-id: (get member-id member-info) }
      (merge member-data { total-proposals: (+ (get total-proposals member-data) u1) })
    )
    (ok true)
  )
)

(define-private (update-member-votes (member-address principal))
  (let
    (
      (member-info (unwrap! (map-get? member-addresses { address: member-address }) ERR_NOT_MEMBER))
      (member-data (unwrap! (map-get? members { member-id: (get member-id member-info) }) ERR_NOT_MEMBER))
    )
    (map-set members
      { member-id: (get member-id member-info) }
      (merge member-data { total-votes: (+ (get total-votes member-data) u1) })
    )
    (ok true)
  )
)

(define-read-only (get-member-by-address (member-address principal))
  (match (map-get? member-addresses { address: member-address })
    member-info (map-get? members { member-id: (get member-id member-info) })
    none
  )
)

(define-read-only (get-member-by-id (member-id uint))
  (map-get? members { member-id: member-id })
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-current-voting-power (member-address principal))
  (match (get-member-by-address member-address)
    member-data
    (let
      (
        (blocks-since-activity (- stacks-block-height (get last-activity member-data)))
        (decay-periods (/ blocks-since-activity DECAY_PERIOD))
        (base-power (get voting-power member-data))
        (activity-bonus (+ (* (get total-proposals member-data) u100) (* (get total-votes member-data) u50)))
      )
      (if (> decay-periods u10)
        u0
        (+ (- base-power (* decay-periods u100)) activity-bonus)
      )
    )
    u0
  )
)

(define-read-only (get-total-active-voting-power)
  (let
    (
      (current-member-id (var-get next-member-id))
    )
    (fold + (map get-member-voting-power-by-id (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10)) u0)
  )
)

(define-private (get-member-voting-power-by-id (member-id uint))
  (match (get-member-by-id member-id)
    member-data (get-current-voting-power (get address member-data))
    u0
  )
)

(define-read-only (is-proposal-active (proposal-id uint))
  (match (get-proposal proposal-id)
    proposal (and
      (<= stacks-block-height (get voting-ends-at proposal))
      (not (get executed proposal))
    )
    false
  )
)

(define-read-only (get-proposal-results (proposal-id uint))
  (match (get-proposal proposal-id)
    proposal
    (some {
      votes-for: (get votes-for proposal),
      votes-against: (get votes-against proposal),
      total-votes: (+ (get votes-for proposal) (get votes-against proposal)),
      passed: (> (get votes-for proposal) (get votes-against proposal)),
      executed: (get executed proposal)
    })
    none
  )
)

(define-read-only (get-member-stats (member-address principal))
  (match (get-member-by-address member-address)
    member-data
    (some {
      current-voting-power: (get-current-voting-power member-address),
      base-voting-power: (get voting-power member-data),
      last-activity: (get last-activity member-data),
      joined-at: (get joined-at member-data),
      total-proposals: (get total-proposals member-data),
      total-votes: (get total-votes member-data),
      blocks-inactive: (- stacks-block-height (get last-activity member-data))
    })
    none
  )
)
