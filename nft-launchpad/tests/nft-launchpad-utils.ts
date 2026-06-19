import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt, Bytes } from "@graphprotocol/graph-ts"
import {
  Approval,
  ApprovalForAll,
  ConsecutiveTransfer,
  CoordinatorSet,
  Minted,
  OwnershipTransferRequested,
  OwnershipTransferred,
  PhaseChanged,
  ProvenanceSet,
  ReferralRewarded,
  RevealFulfilled,
  RevealRequested,
  RootUpdated,
  Transfer,
  Withdrawn
} from "../generated/NftLaunchpad/NftLaunchpad"

export function createApprovalEvent(
  owner: Address,
  approved: Address,
  tokenId: BigInt
): Approval {
  let approvalEvent = changetype<Approval>(newMockEvent())

  approvalEvent.parameters = new Array()

  approvalEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam("approved", ethereum.Value.fromAddress(approved))
  )
  approvalEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return approvalEvent
}

export function createApprovalForAllEvent(
  owner: Address,
  operator: Address,
  approved: boolean
): ApprovalForAll {
  let approvalForAllEvent = changetype<ApprovalForAll>(newMockEvent())

  approvalForAllEvent.parameters = new Array()

  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("operator", ethereum.Value.fromAddress(operator))
  )
  approvalForAllEvent.parameters.push(
    new ethereum.EventParam("approved", ethereum.Value.fromBoolean(approved))
  )

  return approvalForAllEvent
}

export function createConsecutiveTransferEvent(
  fromTokenId: BigInt,
  toTokenId: BigInt,
  from: Address,
  to: Address
): ConsecutiveTransfer {
  let consecutiveTransferEvent = changetype<ConsecutiveTransfer>(newMockEvent())

  consecutiveTransferEvent.parameters = new Array()

  consecutiveTransferEvent.parameters.push(
    new ethereum.EventParam(
      "fromTokenId",
      ethereum.Value.fromUnsignedBigInt(fromTokenId)
    )
  )
  consecutiveTransferEvent.parameters.push(
    new ethereum.EventParam(
      "toTokenId",
      ethereum.Value.fromUnsignedBigInt(toTokenId)
    )
  )
  consecutiveTransferEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  consecutiveTransferEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )

  return consecutiveTransferEvent
}

export function createCoordinatorSetEvent(
  vrfCoordinator: Address
): CoordinatorSet {
  let coordinatorSetEvent = changetype<CoordinatorSet>(newMockEvent())

  coordinatorSetEvent.parameters = new Array()

  coordinatorSetEvent.parameters.push(
    new ethereum.EventParam(
      "vrfCoordinator",
      ethereum.Value.fromAddress(vrfCoordinator)
    )
  )

  return coordinatorSetEvent
}

export function createMintedEvent(
  to: Address,
  tokenId: BigInt,
  qty: BigInt,
  phase: i32
): Minted {
  let mintedEvent = changetype<Minted>(newMockEvent())

  mintedEvent.parameters = new Array()

  mintedEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )
  mintedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  mintedEvent.parameters.push(
    new ethereum.EventParam("qty", ethereum.Value.fromUnsignedBigInt(qty))
  )
  mintedEvent.parameters.push(
    new ethereum.EventParam(
      "phase",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(phase))
    )
  )

  return mintedEvent
}

export function createOwnershipTransferRequestedEvent(
  from: Address,
  to: Address
): OwnershipTransferRequested {
  let ownershipTransferRequestedEvent =
    changetype<OwnershipTransferRequested>(newMockEvent())

  ownershipTransferRequestedEvent.parameters = new Array()

  ownershipTransferRequestedEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  ownershipTransferRequestedEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )

  return ownershipTransferRequestedEvent
}

export function createOwnershipTransferredEvent(
  from: Address,
  to: Address
): OwnershipTransferred {
  let ownershipTransferredEvent =
    changetype<OwnershipTransferred>(newMockEvent())

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )

  return ownershipTransferredEvent
}

export function createPhaseChangedEvent(
  oldPhase: i32,
  newPhase: i32
): PhaseChanged {
  let phaseChangedEvent = changetype<PhaseChanged>(newMockEvent())

  phaseChangedEvent.parameters = new Array()

  phaseChangedEvent.parameters.push(
    new ethereum.EventParam(
      "oldPhase",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(oldPhase))
    )
  )
  phaseChangedEvent.parameters.push(
    new ethereum.EventParam(
      "newPhase",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(newPhase))
    )
  )

  return phaseChangedEvent
}

export function createProvenanceSetEvent(hash: Bytes): ProvenanceSet {
  let provenanceSetEvent = changetype<ProvenanceSet>(newMockEvent())

  provenanceSetEvent.parameters = new Array()

  provenanceSetEvent.parameters.push(
    new ethereum.EventParam("hash", ethereum.Value.fromFixedBytes(hash))
  )

  return provenanceSetEvent
}

export function createReferralRewardedEvent(
  referrer: Address,
  minter: Address,
  amount: BigInt
): ReferralRewarded {
  let referralRewardedEvent = changetype<ReferralRewarded>(newMockEvent())

  referralRewardedEvent.parameters = new Array()

  referralRewardedEvent.parameters.push(
    new ethereum.EventParam("referrer", ethereum.Value.fromAddress(referrer))
  )
  referralRewardedEvent.parameters.push(
    new ethereum.EventParam("minter", ethereum.Value.fromAddress(minter))
  )
  referralRewardedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return referralRewardedEvent
}

export function createRevealFulfilledEvent(
  randomOffset: BigInt
): RevealFulfilled {
  let revealFulfilledEvent = changetype<RevealFulfilled>(newMockEvent())

  revealFulfilledEvent.parameters = new Array()

  revealFulfilledEvent.parameters.push(
    new ethereum.EventParam(
      "randomOffset",
      ethereum.Value.fromUnsignedBigInt(randomOffset)
    )
  )

  return revealFulfilledEvent
}

export function createRevealRequestedEvent(requestId: BigInt): RevealRequested {
  let revealRequestedEvent = changetype<RevealRequested>(newMockEvent())

  revealRequestedEvent.parameters = new Array()

  revealRequestedEvent.parameters.push(
    new ethereum.EventParam(
      "requestId",
      ethereum.Value.fromUnsignedBigInt(requestId)
    )
  )

  return revealRequestedEvent
}

export function createRootUpdatedEvent(tier: string, root: Bytes): RootUpdated {
  let rootUpdatedEvent = changetype<RootUpdated>(newMockEvent())

  rootUpdatedEvent.parameters = new Array()

  rootUpdatedEvent.parameters.push(
    new ethereum.EventParam("tier", ethereum.Value.fromString(tier))
  )
  rootUpdatedEvent.parameters.push(
    new ethereum.EventParam("root", ethereum.Value.fromFixedBytes(root))
  )

  return rootUpdatedEvent
}

export function createTransferEvent(
  from: Address,
  to: Address,
  tokenId: BigInt
): Transfer {
  let transferEvent = changetype<Transfer>(newMockEvent())

  transferEvent.parameters = new Array()

  transferEvent.parameters.push(
    new ethereum.EventParam("from", ethereum.Value.fromAddress(from))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )
  transferEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )

  return transferEvent
}

export function createWithdrawnEvent(to: Address, amount: BigInt): Withdrawn {
  let withdrawnEvent = changetype<Withdrawn>(newMockEvent())

  withdrawnEvent.parameters = new Array()

  withdrawnEvent.parameters.push(
    new ethereum.EventParam("to", ethereum.Value.fromAddress(to))
  )
  withdrawnEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return withdrawnEvent
}
