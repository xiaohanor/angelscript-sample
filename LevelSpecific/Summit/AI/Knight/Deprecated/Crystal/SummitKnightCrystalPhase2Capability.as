class USummitKnightCrystalPhase2Capability : UHazeCapability
{
	default CapabilityTags.Add(n"SummitKnightCrystalPhase2");

	ASummitKnightCrystal Crystal;
	USummitKnightCrystalPhaseComponent PhaseComp;

	float Duration = 2;
	float MoveDuration = 1;
	bool bArrived;
	FHazeAcceleratedVector Crystal2Acc;
	FHazeAcceleratedVector Crystal3Acc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Crystal = Cast<ASummitKnightCrystal>(Owner);
		PhaseComp = USummitKnightCrystalPhaseComponent::GetOrCreate(Owner);
		Crystal.Knight2.BlockCapabilities(n"Behaviour", this);
		Crystal.Knight3.BlockCapabilities(n"Behaviour", this);
		//Crystal.Knight2.PossessComp.DeactivateKnight();
		//Crystal.Knight3.PossessComp.DeactivateKnight();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase == 2)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration + MoveDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Crystal.SubCrystal2.DetachFromParent(true);
		Crystal.SubCrystal3.DetachFromParent(true);
		Crystal2Acc.Value = Crystal.SubCrystal2.WorldLocation;
		Crystal3Acc.Value = Crystal.SubCrystal3.WorldLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PhaseComp.Phase = 0;
		Crystal.Knight2.UnblockCapabilities(n"Behaviour", this);
		Crystal.Knight3.UnblockCapabilities(n"Behaviour", this);
		//Crystal.Knight2.PossessComp.ActivateKnight();
		//Crystal.Knight3.PossessComp.ActivateKnight();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Crystal2Acc.AccelerateTo(Crystal.Knight2.ActorCenterLocation, Duration, DeltaTime);
		Crystal3Acc.AccelerateTo(Crystal.Knight3.ActorCenterLocation, Duration, DeltaTime);
		Crystal.SubCrystal2.SetWorldLocation(Crystal2Acc.Value);
		Crystal.SubCrystal3.SetWorldLocation(Crystal3Acc.Value);

		if(ActiveDuration > Duration)
		{
			if(!bArrived)
			{
				Crystal.SubCrystal2.AddComponentVisualsBlocker(this);
				Crystal.SubCrystal3.AddComponentVisualsBlocker(this);
				bArrived = true;
			}
			//Crystal.Knight2.PossessComp.IntroMovement((ActiveDuration - Duration) / MoveDuration);
			//Crystal.Knight3.PossessComp.IntroMovement((ActiveDuration - Duration) / MoveDuration);
		}
	}
}