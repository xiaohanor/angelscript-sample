class USkylineBossTankCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 102;

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
			// States
			.Add(UHazeCompoundSequence()
				.Then(USkylineBossTankLiftEntryCapability())
				.Then(USkylineBossTankHoldFireCapability())
			)
			
			.Add(USkylineBossTankCutsceneCapability())
			.Add(USkylineBossTankDangerWidgetCapability())
			.Add(USkylineBossTankDangerDecalCapability())
			.Add(USkylineBossTankFollowTargetCapability())
			.Add(USkylineBossTankEngineCapability())
			.Add(USkylineBossTankChangeTargetOnDamageCapability())
			.Add(USkylineBossTankChangeTargetCapability())
			.Add(USkylineBossTankCenterCapability())
			.Add(USkylineBossTankAssembleCapability())
			.Add(USkylineBossTankMortarBallTargetCapability())
			.Add(USkylineBossTankMortarBallAttackCapability())
			.Add(USkylineBossTankAutoCannonAttackCapability())
			.Add(USkylineBossTankPlayerRespawnCapability())
			.Add(USkylineBossTankTurretCapability())
			.Add(USkylineBossTankWeakPointCapability())
			.Add(USkylineBossTankCrusherCapability())
			.Add(USkylineBossTankCrusherBlastAttackCapability())
			.Add(USkylineBossTankMovementCapability())
			.Add(USkylineBossTankTargetSpotlightCapability())
		;
	}
}