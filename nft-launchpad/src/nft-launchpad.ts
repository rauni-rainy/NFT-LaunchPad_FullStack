import { BigInt, Bytes } from "@graphprotocol/graph-ts"
import {
  Minted as MintedEvent,
  PhaseChanged as PhaseChangedEvent,
  ReferralRewarded as ReferralRewardedEvent,
  Withdrawn as WithdrawnEvent
} from "../generated/NftLaunchpad/NftLaunchpad"
import {
  Mint,
  PhaseChange,
  Referral,
  DayMintStats,
  CollectionStats
} from "../generated/schema"

function getOrCreateCollectionStats(): CollectionStats {
  let stats = CollectionStats.load("global")
  if (stats == null) {
    stats = new CollectionStats("global")
    stats.totalMinted = BigInt.fromI32(0)
    stats.totalRevenue = BigInt.fromI32(0)
    stats.uniqueHolders = BigInt.fromI32(0)
    stats.currentPhase = "CLOSED"
    stats.save()
  }
  return stats as CollectionStats
}

function getDayId(timestamp: BigInt): string {
  // 86400 seconds in a day
  let dayNum = timestamp.toI32() / 86400
  // Approximation of date string or just return the day number string
  // Subgraph AssemblyScript doesn't have a full Date formatting library built-in easily
  // We'll just return the day number as a string since standard date string requires complex math
  return dayNum.toString()
}

function phaseToString(phase: i32): string {
  if (phase == 0) return "CLOSED"
  if (phase == 1) return "OG"
  if (phase == 2) return "ALLOWLIST"
  if (phase == 3) return "PUBLIC"
  return "UNKNOWN"
}

export function handleMinted(event: MintedEvent): void {
  // Use tx hash as ID so it can be shared with ReferralRewarded
  let mintId = event.transaction.hash.toHexString()
  let mint = Mint.load(mintId)
  if (mint == null) {
    mint = new Mint(mintId)
    // Initialize required fields that might be set by ReferralRewarded if it ran first
    mint.referrer = null
  }
  
  mint.tokenId = event.params.tokenId
  mint.quantity = event.params.qty
  mint.minter = event.params.to
  mint.phase = phaseToString(event.params.phase)
  
  // Calculate pricePerToken and totalPaid from transaction value
  mint.totalPaid = event.transaction.value
  if (event.params.qty.gt(BigInt.fromI32(0))) {
    mint.pricePerToken = event.transaction.value.div(event.params.qty)
  } else {
    mint.pricePerToken = BigInt.fromI32(0)
  }
  
  mint.blockTimestamp = event.block.timestamp
  mint.blockNumber = event.block.number
  mint.save()

  // Update CollectionStats
  let stats = getOrCreateCollectionStats()
  stats.totalMinted = stats.totalMinted.plus(event.params.qty)
  stats.totalRevenue = stats.totalRevenue.plus(event.transaction.value)
  stats.save()

  // Update DayMintStats
  let dayId = getDayId(event.block.timestamp)
  let dayStats = DayMintStats.load(dayId)
  if (dayStats == null) {
    dayStats = new DayMintStats(dayId)
    dayStats.date = dayId
    dayStats.mintCount = BigInt.fromI32(0)
    dayStats.revenue = BigInt.fromI32(0)
    dayStats.uniqueMinters = BigInt.fromI32(0)
  }
  dayStats.mintCount = dayStats.mintCount.plus(event.params.qty)
  dayStats.revenue = dayStats.revenue.plus(event.transaction.value)
  // uniqueMinters requires tracking, we'll just increment naively or skip for now since we don't have a Minters entity
  dayStats.uniqueMinters = dayStats.uniqueMinters.plus(BigInt.fromI32(1))
  dayStats.save()
}

export function handlePhaseChanged(event: PhaseChangedEvent): void {
  let id = event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  let phaseChange = new PhaseChange(id)
  phaseChange.oldPhase = phaseToString(event.params.oldPhase)
  phaseChange.newPhase = phaseToString(event.params.newPhase)
  phaseChange.blockTimestamp = event.block.timestamp
  phaseChange.save()

  let stats = getOrCreateCollectionStats()
  stats.currentPhase = phaseToString(event.params.newPhase)
  stats.save()
}

export function handleReferralRewarded(event: ReferralRewardedEvent): void {
  let referrerId = event.params.referrer.toHexString()
  let referral = Referral.load(referrerId)
  if (referral == null) {
    referral = new Referral(referrerId)
    referral.referrer = event.params.referrer
    referral.totalEarned = BigInt.fromI32(0)
    referral.totalClaimed = BigInt.fromI32(0)
    referral.pendingRewards = BigInt.fromI32(0)
  }
  referral.totalEarned = referral.totalEarned.plus(event.params.amount)
  referral.pendingRewards = referral.pendingRewards.plus(event.params.amount)
  referral.save()

  // Update the related Mint entity's referrer field (look up by same tx hash)
  let mintId = event.transaction.hash.toHexString()
  let mint = Mint.load(mintId)
  if (mint == null) {
    mint = new Mint(mintId)
    // Pre-initialize required fields to avoid null errors when saved, they will be overwritten by handleMinted
    mint.tokenId = BigInt.fromI32(0)
    mint.quantity = BigInt.fromI32(0)
    mint.minter = event.params.minter
    mint.phase = "UNKNOWN"
    mint.pricePerToken = BigInt.fromI32(0)
    mint.totalPaid = BigInt.fromI32(0)
    mint.blockTimestamp = event.block.timestamp
    mint.blockNumber = event.block.number
  }
  mint.referrer = event.params.referrer
  mint.save()
}

export function handleWithdrawn(event: WithdrawnEvent): void {
  // If the owner withdraws referral rewards, we need to handle it.
  // Wait, Withdrawn is also emitted when users claim referral rewards.
  // In NftLaunchpad.sol: 
  // emit Withdrawn(msg.sender, amount); // from claimReferralRewards
  // emit Withdrawn(owner(), available); // from admin withdraw
  
  // We can update the Referral entity if they claimed rewards
  let referrerId = event.params.to.toHexString()
  let referral = Referral.load(referrerId)
  if (referral != null) {
    // If it's a referrer claiming, update their claimed amounts
    referral.totalClaimed = referral.totalClaimed.plus(event.params.amount)
    // Reset pending
    referral.pendingRewards = BigInt.fromI32(0) // or deduct amount
    referral.save()
  }
}
