struct FSanctuaryGrimbeastActionRaisePillarsData
{
	ASanctuaryGrimbeastPillar PillarToRaise;
	float Duration;
	float HeightMultiplier;
}

class USanctuaryGrimbeastActionRaisePillarsCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryGrimbeastActionRaisePillarsData Params;
	default CapabilityTags.Add(GrimbeastTags::Grimbeast);
	default CapabilityTags.Add(GrimbeastTags::Action);
	USanctuaryGrimbeastActionsComponent ActionComp;
	AAISanctuaryGrimbeast Grimbeast;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActionComp = USanctuaryGrimbeastActionsComponent::GetOrCreate(Owner);
		Grimbeast = Cast<AAISanctuaryGrimbeast>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryGrimbeastActionRaisePillarsData& ActivationParams) const
	{
		if (ActionComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryGrimbeastActionRaisePillarsData ActivationParams)
	{
		Params = ActivationParams;
		if (Params.PillarToRaise != nullptr)
			Params.PillarToRaise.Raise(Params.Duration, Params.HeightMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ActionComp.ActionQueue.Finish(this);
	}
}
