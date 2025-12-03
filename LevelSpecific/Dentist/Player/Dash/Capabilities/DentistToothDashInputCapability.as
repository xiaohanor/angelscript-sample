class UDentistToothDashInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UDentistToothDashComponent DashComp;

	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DashComp = UDentistToothDashComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;
		
		if(!WasActionStarted(ActionNames::MovementDash))
			return false;

		if(MoveComp.IsInAir())
		{
			if(!DashComp.CanDash())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::MovementDash))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DashComp.bIsInputtingDash = true;
		DashComp.StartDashInputFrame = Time::FrameNumber;
		DashComp.StartDashInputTime = Time::RealTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DashComp.bIsInputtingDash = false;

		if(IsBlocked())
			DashComp.ConsumeDashInput();
	}
};