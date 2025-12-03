class USummitTrapperReturnTrapBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	AAISummitTrapper SummitTrapper;
	UGentlemanCostComponent GentCostComp;
	USummitTrapperTrapComponent TrapComp;

	// float Speed;
	float ReturnDuration = 0.5;

	bool bHoldingTrap;

	FHazeAcceleratedVector ReturnAcc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		TrapComp = USummitTrapperTrapComponent::GetOrCreate(Owner);
		SummitTrapper = Cast<AAISummitTrapper>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!TargetComp.HasValidTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if(ActiveDuration > ReturnDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TrapComp.ReleaseDragon();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		TrapComp.ReleaseTrap();
		GentCostComp.ReleaseToken(TrapComp);	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (TrapComp.Trap == nullptr)
			return;

		ReturnAcc.Value = TrapComp.Trap.ActorLocation;
		ReturnAcc.AccelerateTo(SummitTrapper.ActorCenterLocation, ReturnDuration, DeltaTime);
		TrapComp.Trap.ActorLocation = ReturnAcc.Value;

		DestinationComp.RotateTowards(TrapComp.TrapTargetLocation);
	}
} 