class UGravityBikeSplineAirStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineJumpComponent JumpComp;

	float AirTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UGravityBikeSplineMovementComponent::Get(GravityBike);
		JumpComp = UGravityBikeSplineJumpComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(JumpComp.IsJumping())
			return true;
		
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
		GravityBike.SteeringComp.bCenterSteering.Apply(false, this);
		GravityBike.OnLeaveGround();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.IsAirborne.Clear(this);
		GravityBike.SteeringComp.bCenterSteering.Clear(this);
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