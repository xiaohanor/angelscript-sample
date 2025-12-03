class USummitKnightMobileStartIntroCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::MobileStart;
	default Round = 0;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		// We're in this compound at the very start of the fight
		return UHazeCompoundSelector()
				.Try(USummitKnightMobileIntroBehaviour())
				
				// If hurt enough or stunned by smashed crystal we will start the main round of this phase
				.Try(UHazeCompoundStatePicker()
					.State(UHazeCompoundSequence()
						.Then(USummitKnightMobileHurtReactionBehaviour())
						.Then(USummitKnightSwoopAcrossArenaBehaviour())
						.Then(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileStart, 1))
					)
					.State(UHazeCompoundSequence()
						.Then(USummitKnightMobileStunnedBehaviour())
						.Then(USummitKnightSwoopAcrossArenaBehaviour())
						.Then(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileStart, 1))
					)
				)

				// Until hurt/stunned we make simple attacks
				.Try(UHazeCompoundSequence()
					.Then(USummitKnightSingleSlashBehaviour())
					.Then(USummitKnightSingleSlashBehaviour())
					.Then(USummitKnightPauseBehaviour(1.0))
				)
			;
	}
}

class USummitKnightMobileStartLoopCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::MobileStart;
	default Round = 1;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		// This is the main attack loop of the start phase
		return UHazeCompoundSelector()
				// Slam when taken enough damage, then either progress to next phase or swoop to arena edge
				.Try(UHazeCompoundSequence()
					.Then(USummitKnightMobileStartSlamAttackBehaviour(true))
					.Then(UHazeCompoundSelector()
						.Try(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileCircling, 0))	
						.Try(USummitKnightSwoopAcrossArenaBehaviour())
					)
				)

				// We can progress to next phase when damaged enough at any time when not slamming.
				.Try(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileCircling, 0))
				
				// Stuns will be followed by swoop
				.Try(UHazeCompoundSequence()
					.Then(USummitKnightMobileStunnedBehaviour())
					.Then(USummitKnightSwoopAcrossArenaBehaviour())
				)

				// Main attack sequence
				.Try(UHazeCompoundRunAll()
					.Add(UHazeCompoundSequence()
						.Then(USummitKnightSpinningSlashBehaviour())
						.Then(USummitKnightSingleSlashBehaviour())
						.Then(USummitKnightSingleSlashBehaviour())
						.Then(USummitKnightSwoopAcrossArenaBehaviour())
					)
				)
			;
	}
}

class USummitKnightMobileCirclingCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::MobileCircling;
	default Round = 0;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(USummitKnightCirclingIntroBehaviour(true))
				.Add(UHazeCompoundSequence()
					.Then(USummitKnightSummonCrittersBehaviour())
					.Then(USummitKnightPauseBehaviour(1.0))
					.Then(USummitKnightSummonCrittersBehaviour())
					.Then(USummitKnightPauseBehaviour(2.0))
					.Then(USummitKnightLargeAreaStrikeBehaviour())
					.Then(USummitKnightPauseBehaviour(1.0))
					.Then(USummitKnightSummonCrittersBehaviour())
					.Then(USummitKnightPauseBehaviour(1.0))
					.Then(USummitKnightSwoopAcrossArenaBehaviour()) // Move to arena while meteors are shooting down
					.Then(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileMain, 0))
				)
				.Add(USummitKnightCircleArenaBehaviour())
				;
	}
}

class USummitKnightMobileMainTrackingFlamesCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::MobileMain;
	default Round = 0;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSelector()

				// Slam when taken enough damage, then either progress to next phase or swoop to arena edge
				.Try(UHazeCompoundSequence()
					.Then(USummitKnightMobileMainSlamAttackBehaviour(true))
					.Then(UHazeCompoundSelector()
						.Try(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileEndCircling, 0))	
						.Try(USummitKnightSwoopAcrossArenaBehaviour())
					)
				)

				// We can progress to next phase when damaged enough at any time when not slamming.
				.Try(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileEndCircling, 0))
				
				// Stuns will be followed by swoop
				.Try(UHazeCompoundSequence()
					.Then(USummitKnightMobileStunnedBehaviour())
					.Then(USummitKnightSwoopAcrossArenaBehaviour())
					.Then(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileMain, 1))	
				)

				// Main attack sequence
				.Try(UHazeCompoundRunAll()
					.Add(UHazeCompoundSequence()
						.Then(USummitKnightCrystalTrailBehaviour())
						.Then(USummitKnightPauseBehaviour(2.0))
						.Then(USummitKnightSingleSlashBehaviour())
						.Then(USummitKnightSingleSlashBehaviour())
						.Then(USummitKnightSwoopAcrossArenaBehaviour())
						.Then(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileMain, 1))	
					)
					.Add(USummitKnightCircleDodgeBehaviour())
				)
			;
	}
}

class USummitKnightMobileMainHomingFireballsCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::MobileMain;
	default Round = 1;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSelector()

				// Slam when taken enough damage, then either progress to next phase or swoop to arena edge
				.Try(UHazeCompoundSequence()
					.Then(USummitKnightMobileMainSlamAttackBehaviour(true))
					.Then(UHazeCompoundSelector()
						.Try(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileEndCircling, 0))	
						.Try(USummitKnightSwoopAcrossArenaBehaviour())
					)
				)

				// We can progress to next phase when damaged enough at any time when not slamming.
				.Try(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileEndCircling, 0))
				
				// Stuns will be followed by swoop
				.Try(UHazeCompoundSequence()
					.Then(USummitKnightMobileStunnedBehaviour())
					.Then(USummitKnightSwoopAcrossArenaBehaviour())
					.Then(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileMain, 0))	
				)

				// Main attack sequence
				.Try(UHazeCompoundRunAll()
					.Add(UHazeCompoundSequence()
						.Then(USummitKnightHomingFireballsBehaviour())
						.Then(USummitKnightPauseBehaviour(2.0))
						.Then(USummitKnightSingleSlashBehaviour())
						.Then(USummitKnightSingleSlashBehaviour())
						.Then(USummitKnightSwoopAcrossArenaBehaviour())
						.Then(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileMain, 0))	
					)
					.Add(USummitKnightCircleDodgeBehaviour())
				)
			;
	}
}

class USummitKnightMobileEndCirclingCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::MobileEndCircling;
	default Round = 0;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(USummitKnightCirclingIntroBehaviour())
				.Add(UHazeCompoundSequence()
					.Then(USummitKnightLargeAreaStrikeBehaviour())
					.Then(USummitKnightSpinningSlashBehaviour())
					.Then(USummitKnightPauseBehaviour(1.0))
					.Then(USummitKnightSpinningSlashBehaviour())
					.Then(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileEndRun, 0))
				)
				.Add(USummitKnightCircleArenaBehaviour())
				;
	}
}

class USummitKnightMobileEndRunCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::MobileEndRun;
	default Round = 0;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSelector()
				// Final stand when sufficiently hurt
				.Try(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileAlmostDead, 0))

				// Stun
				.Try(UHazeCompoundSequence()
					.Then(USummitKnightMobileStunnedBehaviour())
				)

				// Main attack sequence
				.Try(UHazeCompoundRunAll()
					.Add(UHazeCompoundSequence()
						.Then(USummitKnightSwoopTackleBehaviour())
						.Then(USummitKnightSmashGroundBehaviour())
						.Then(USummitKnightPauseBehaviour(0.2))
						.Then(USummitKnightSmashGroundBehaviour())
						.Then(USummitKnightMobileEndSlamAttackBehaviour())
					)
				)
			;
	}
}

class USummitKnightMobileAlmostDeadCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::MobileAlmostDead;
	default Round = 0;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		// Recoil to final destination, then attack from there
		return UHazeCompoundSelector()
				.Try(USummitKnightAlmostDeadIntroBehaviour())
				.Try(UHazeCompoundSequence()
					.Then(USummitKnightAlmostDeadSmashBehaviour())
					.Then(USummitKnightPauseBehaviour(0.2))
				)
			;
	}
}

class USummitKnightMobileEndCirclingShortCompoundCapability : USummitKnightStagesCompoundCapability
{
	default Phase = ESummitKnightPhase::MobileEndCircling;
	default Round = 1;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(USummitKnightCirclingIntroBehaviour())
				.Add(UHazeCompoundSequence()
					.Then(USummitKnightLargeAreaStrikeBehaviour())
					.Then(USummitKnightSpinningSlashBehaviour())
					.Then(USummitKnightPauseBehaviour(1.0))
					.Then(USummitKnightSpinningSlashBehaviour())
					.Then(USummitKnightCheckProgressCapability(ESummitKnightPhase::MobileEndRun, 0))
				)
				.Add(USummitKnightCircleArenaBehaviour())
				;
	}
}

// Not used, just a convenient repository for all attacks while experimenting
class USummitKnightAllAttacksCompoundCapability : UHazeCompoundCapability
{
	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundSequence()
					.Then(USummitKnightSingleSlashBehaviour())
					.Then(USummitKnightDualSlashBehaviour())
					.Then(USummitKnightHomingFireballsBehaviour())
					.Then(USummitKnightAreaDenialFireballBehaviour())
					.Then(USummitKnightSpinningSlashBehaviour())
					.Then(USummitKnightShockwaveBehaviour())
					.Then(USummitKnightSummonCrittersBehaviour())
					.Then(USummitKnightStopSummoningBehaviour())
					.Then(USummitKnightCrystalWallBehaviour())
					.Then(USummitKnightMetalWallBehaviour())
					.Then(USummitKnightRotatingCrystalBehaviour())
					.Then(USummitKnightCrystalTrailBehaviour())
					.Then(USummitKnightSummonObstaclesBehaviour())
					.Then(USummitKnightLargeAreaStrikeBehaviour())
					.Then(USummitKnightSmashGroundBehaviour())
			;
	}
}