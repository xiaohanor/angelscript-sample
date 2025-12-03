class USkylineBallBossCompoundCapability : UHazeCompoundCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::BallBossBlockedInCutsceneTag);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	ASkylineBallBoss BallBoss;

	// Ball boss movement must tick before UGravityBladeGrappleGravityAlignCapability
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			.Add(UHazeCompoundSelector()
				// Select rotation mode
				.Try(USkylineBallBossRotateFreezeCapability())
				.Try(USkylineBallBossChaseSplineCapability())
				.Try(USkylineBallBossRotateAfterLosingWeakpointCapability())
				.Try(USkylineBallBossRotatePartTowardsStageCapability())
				// .Try(USkylineBallBossRotateAfterDetonatorHurtCapability())
				.Try(USkylineBallBossRotateDontLookAtZoeCapability())
				// .Try(USkylineBallBossRotateAfterDetonatorImpactCapability())
				.Try(USkylineBallBossRotateSnapOverrideCapability())
				.Try(USkylineBallBossRotateTowardsPlayerCapability())
			)

			// check shield conditions
			.Add(UHazeCompoundRunAll()
				.Add(USkylineBallBossFlashShieldCapability())
				.Add(USkylineBallBossShieldShockwaveCapability())
				.Add(USkylineBallBossLaunchMioToStageCapability())
			)

			.Add(USkylineBallBossBlinkCapability())
			.Add(USkylineBallBossTelegraphPulseEyeCapability())
			.Add(USkylineBallBossTelegraphRedEyeCapability())

			// pulse when eye breaks
			.Add(USkylineBallBossDisintegratePulseCapability())
		;
	}
}
