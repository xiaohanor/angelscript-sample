class USummitKnightCrystalPhase3Capability : UHazeCapability
{
	default CapabilityTags.Add(n"SummitKnightCrystalPhase3");

	ASummitKnightCrystal Crystal;
	USummitKnightCrystalPhaseComponent PhaseComp;

	float Duration = 6;
	FHazeAcceleratedVector CrystalAcc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Crystal = Cast<ASummitKnightCrystal>(Owner);
		PhaseComp = USummitKnightCrystalPhaseComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase == 3)
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
		CrystalAcc.Value = Crystal.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PhaseComp.Phase = 0;
		Crystal.AddActorVisualsBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CrystalAcc.AccelerateTo(Crystal.HorseKnight.ActorCenterLocation, Duration, DeltaTime);
		Crystal.SetActorLocation(CrystalAcc.Value);
	}
}