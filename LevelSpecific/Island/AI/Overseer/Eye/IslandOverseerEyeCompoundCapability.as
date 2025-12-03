class UIslandOverseerEyeCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	AAIIslandOverseerEye Eye;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Eye = Cast<AAIIslandOverseerEye>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Eye.Active)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Eye.Active)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		Eye.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					.Try(UIslandOverseerEyeExitBehaviour())
					.Try(UIslandOverseerEyeEnterBehaviour())
					.Try(UIslandOverseerEyeFlyByAttackBehaviour())
					.Try(UIslandOverseerChargeAttackBehaviour())
					.Try(UIslandOverseerEyeIdleBehaviour())
				)
			;
	}
}

