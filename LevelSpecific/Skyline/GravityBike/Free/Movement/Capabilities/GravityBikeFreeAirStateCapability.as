class UGravityBikeFreeAirStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;

	float AirTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AirTime < GravityBike.Settings.BecomeAirborneDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike.IsAirborne.Apply(true, this);
		GravityBike.OnLeaveGround();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.IsAirborne.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsActive())
		{
			if(MoveComp.HasGroundContact())
				AirTime = 0.0;
			else
				AirTime += DeltaTime;
		}
	}
}