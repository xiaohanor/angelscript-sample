class USummitKnightCrystalPhase1Capability : UHazeCapability
{
	default CapabilityTags.Add(n"SummitKnightCrystalPhase1");

	ASummitKnightCrystal Crystal;
	USummitKnightCrystalPhaseComponent PhaseComp;

	float Duration = 2;
	FHazeAcceleratedVector Crystal1Acc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Crystal = Cast<ASummitKnightCrystal>(Owner);
		PhaseComp = USummitKnightCrystalPhaseComponent::GetOrCreate(Owner);
		Crystal.Knight1.BlockCapabilities(n"Behaviour", this);
		//Crystal.Knight1.PossessComp.DeactivateKnight();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase == 1)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Crystal.SubCrystal1.DetachFromParent(true);
		Crystal1Acc.Value = Crystal.SubCrystal1.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PhaseComp.Phase = 0;
		Crystal.SubCrystal1.AddComponentVisualsBlocker(this);
		Crystal.Knight1.UnblockCapabilities(n"Behaviour", this);
		//Crystal.Knight1.PossessComp.ActivateKnight();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Crystal1Acc.AccelerateTo(Crystal.Knight1.ActorCenterLocation, Duration, DeltaTime);
		Crystal.SubCrystal1.SetWorldLocation(Crystal1Acc.Value);
	}
}