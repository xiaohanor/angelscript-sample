UCLASS(NotBlueprintable)
class UGravityBikeSplineSteeringComponent : UActorComponent
{
	access Internal = private, UGravityBikeSplineSteeringCapability;

	private AGravityBikeSpline GravityBike;
	private UGravityBikeSplineMovementComponent MoveComp;

	FHazeAcceleratedFloat AccSteering;
	
	TInstigated<float> SteeringMultiplier;
	default SteeringMultiplier.DefaultValue = 1.0;

	TInstigated<bool> bCenterSteering;
	default bCenterSteering.DefaultValue = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = GravityBike.MoveComp;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if !RELEASE
		const FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog
			.Value("Steering;AccSteering", AccSteering.Value)
			.Value("Steering;SteeringMultiplier", SteeringMultiplier.Get())
		;
#endif
	}

	float GetSteerAlpha(float Speed, bool bAccelerated) const
	{
		const float Steering = bAccelerated ? AccSteering.Value : GravityBike.Input.GetSteering();
		return Steering * GravityBike.GetSpeedAlpha(Speed);
	}

	float GetMaxSteerAngleDeg(float Speed) const
	{
		const float SpeedAlpha = Math::GetPercentageBetweenClamped(GravityBike.Settings.SlowSpeedThreshold, GravityBike.Settings.FastSpeedThreshold, Speed);
		return Math::Lerp(GravityBike.Settings.SlowMaxSteeringAngleDeg, GravityBike.Settings.FastMaxSteeringAngleDeg, SpeedAlpha);
	}

	float GetSteeringAngleRad(float Speed) const
	{
		const float SteerAngleDeg = GetMaxSteerAngleDeg(Speed);
		const float SteerAngleRad = Math::DegreesToRadians(SteerAngleDeg);
		return AccSteering.Value * SteerAngleRad;
	}

	FQuat GetTargetSteerRelativeRotation() const
	{
		float Speed = MoveComp.HorizontalVelocity.Size();
		const float SteeringAngle = GetSteeringAngleRad(Speed);
		return FQuat(GravityBike.AccBikeUp.Value.UpVector, SteeringAngle);
	}

	float GetMaxTurnAngle() const
	{
		float SteeringAmount = GravityBike.Settings.FastMaxSteeringAngleDeg;
		return SteeringAmount * GravityBike.Settings.MaxSpeed * 0.001;
	}

	FVector GetSteeringWorldDir() const
	{
		return GravityBike.ActorTransform.TransformVectorNoScale(GetSteeringRelativeDir());
	}

	FVector GetSteeringRelativeDir() const
	{
		return GetSteeringRelativeRot().ForwardVector;
	}

	FQuat GetSteeringWorldRot() const
	{
		return GravityBike.ActorTransform.TransformRotation(GetSteeringRelativeRot());
	}

	FQuat GetSteeringRelativeRot() const
	{
		return FRotator(0.0, GetSteeringAngleRad(GravityBike.GetForwardSpeed()), 0.0).Quaternion();
	}
};