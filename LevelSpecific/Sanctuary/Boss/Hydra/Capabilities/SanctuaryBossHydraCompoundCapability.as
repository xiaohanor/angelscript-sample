class USanctuaryBossHydraCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(UHazeCompoundSelector()
				.Try(UHazeCompoundSequence()
					.Then(n"SanctuaryBossHydraSmashEnterCapability")
					.Then(n"SanctuaryBossHydraSmashTelegraphCapability")
					.Then(n"SanctuaryBossHydraSmashAttackCapability")
					.Then(n"SanctuaryBossHydraSmashRecoverCapability")
					.Then(n"SanctuaryBossHydraSmashReturnCapability")
				)
				.Try(UHazeCompoundSequence()
					.Then(n"SanctuaryBossHydraFireBreathEnterCapability")
					.Then(n"SanctuaryBossHydraFireBreathTelegraphCapability")
					.Then(n"SanctuaryBossHydraFireBreathAttackCapability")
					.Then(n"SanctuaryBossHydraFireBreathRecoverCapability")
					.Then(n"SanctuaryBossHydraFireBreathReturnCapability")
				)
				.Try(UHazeCompoundSequence()
					.Then(n"SanctuaryBossHydraFireBallEnterCapability")
					.Then(n"SanctuaryBossHydraFireBallAttackCapability")
					.Then(n"SanctuaryBossHydraFireBallReturnCapability")
				)
				.Try(n"SanctuaryBossHydraIdleCapability")
			)
			.Add(n"SanctuaryBossHydraSplineMeshCapability");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}
}