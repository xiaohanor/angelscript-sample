class UGravityBikeSplineAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSplineAnimation);

	default TickGroup = EHazeTickGroup::LastMovement;

	AGravityBikeSpline GravityBike;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GravityBike.AnimationData.Speed = GravityBike.GetForwardSpeed();
		FRotator AngularVelocity = FauxPhysics::Calculation::VecToQuat(GravityBike.AngularVelocity).Rotator();
		GravityBike.AnimationData.AngularVelocity = AngularVelocity;

		const float MaxAngularSpeed = GravityBike.Settings.FastMaxSteeringAngleDeg * 3.3333;	// This number seems to be correct for some reason lol
		GravityBike.AnimationData.AngularSpeed = -Math::Clamp(GravityBike.AnimationData.AngularVelocity.Yaw / MaxAngularSpeed, -1, 1);

		GravityBike.AnimationData.Steering = GravityBike.SteeringComp.GetSteerAlpha(GravityBike.GetForwardSpeed(), true);
	}
}