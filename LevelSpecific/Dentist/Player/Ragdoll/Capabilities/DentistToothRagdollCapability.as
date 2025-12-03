class UDentistToothRagdollCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;

	UDentistToothRagdollComponent RagdollComp;
	UDentistToothDashComponent DashComp;
	UDentistToothGroundPoundComponent GroundPoundComp;

	UPlayerMovementComponent MoveComp;

	bool bBlockingMovement = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RagdollComp = UDentistToothRagdollComponent::Get(Player);
		DashComp = UDentistToothDashComponent::Get(Player);
		GroundPoundComp = UDentistToothGroundPoundComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!RagdollComp.bShouldRagdoll)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!RagdollComp.bShouldRagdoll)
			return true;

		if(DashComp.IsDashing())
			return true;

		if(GroundPoundComp.IsGroundPounding())
			return true;

		if(!bBlockingMovement)
		{
			if(MoveComp.IsOnAnyGround())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RagdollComp.bIsRagdolling = true;

		BlockMovement();

		UDentistToothEventHandler::Trigger_OnStartRagdoll(Player);

		Player.BlockCapabilities(Dentist::Tags::CancelOnRagdoll, this);
		Player.UnblockCapabilities(Dentist::Tags::CancelOnRagdoll, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RagdollComp.bShouldRagdoll = false;
		RagdollComp.bIsRagdolling = false;

		DashComp.ResetDashUsage();
		GroundPoundComp.ResetAirGroundPoundUsage();

		if(bBlockingMovement)
			UnblockMovement();

		UDentistToothEventHandler::Trigger_OnStopRagdoll(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bBlockingMovement && Time::GetGameTimeSince(RagdollComp.LastHitTime) > RagdollComp.Settings.StopAfterDelay)
		{
			UnblockMovement();
		}
	}

	private void BlockMovement()
	{
		check(!bBlockingMovement);
		Player.BlockCapabilities(Dentist::Tags::Dash, this);
		Player.BlockCapabilities(Dentist::Tags::GroundPound, this);
		RagdollComp.bAllowAirMovement.Apply(false, this);
		bBlockingMovement = true;
	}

	private void UnblockMovement()
	{
		check(bBlockingMovement);
		Player.UnblockCapabilities(Dentist::Tags::Dash, this);
		Player.UnblockCapabilities(Dentist::Tags::GroundPound, this);
		RagdollComp.bAllowAirMovement.Clear(this);
		bBlockingMovement = false;
	}
};