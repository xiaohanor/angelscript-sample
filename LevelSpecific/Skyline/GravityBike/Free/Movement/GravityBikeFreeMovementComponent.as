class UGravityBikeFreeMovementComponent : UHazeMovementComponent
{
	private AGravityBikeFree GravityBike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		GravityBike = Cast<AGravityBikeFree>(Owner);

		OverrideResolver(UGravityBikeFreeMovementResolver, this);

		UMovementStandardSettings::SetAlsoUseActorUpForWalkableSlopeAngle(GravityBike, true, this);
		UMovementSteppingSettings::SetStepUpSize(GravityBike, FMovementSettingsValue::MakePercentage(100), this);
	}

	float GetForwardSpeed() const
	{
		return Velocity.DotProduct(Owner.ActorForwardVector);
	}

	float GetForwardSpeed(FVector HorizontalPlaneNormal) const
	{
		return Velocity.DotProduct(GetHorizontalForward(HorizontalPlaneNormal));
	}
	
	FVector GetHorizontalForward(FVector HorizontalPlaneNormal) const
	{
		return Owner.ActorForwardVector.VectorPlaneProject(HorizontalPlaneNormal).GetSafeNormal();
	}

	/**
	 * Acceleration Based
	 */

	/**
	 * Accelerate CurrentSpeed towards the current TargetSpeed.
	 */
	void AccelerateTowardsTargetSpeed(float& CurrentSpeed, float DeltaTime) const
	{
		float TargetSpeed = GetTargetSpeed();

		const bool bIsAccelerating = CurrentSpeed < TargetSpeed;

		float InterpSpeed = bIsAccelerating ? GravityBike.Settings.Acceleration : GravityBike.Settings.Deceleration;

		CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaTime, InterpSpeed);
	}

	float GetMaxSpeed() const
	{
		return Math::Min(GravityBike.Settings.MaxSpeed * GravityBike.Settings.MaxSpeedMultiplier, GravityBike.Settings.MaxSpeedLimit);
	}

	/**
	 * How fast we currently want to move in the forward direction
	 * FB TODO: Move to capabilities?
	 */
	float GetTargetSpeed() const
	{
		return Math::Lerp(GravityBike.Settings.MinimumSpeed, GetMaxSpeed(), GravityBike.Input.Throttle);
	}

	/**
	 * This funky function takes the current velocity (Horizontal AND Vertical)
	 * and injects a new forward speed into it, without changing the vertical speed
	 * What is vertical is decided by Up, so we can change it based on the movement mode
	 */
	void SetForwardSpeed(
		FVector& InVelocity,
		float InNewForwardSpeed,
		FVector InUp,
		float InDeltaTime,
		float InSideSpeedDeceleration
	) const
	{
		// First we calculate the old forward and side velocity. The side velocity is everything on the horizontal
		// plane that is not in the forward direction
		const FVector OldHorizontalVelocity = InVelocity.VectorPlaneProject(InUp);
		const FVector OldForwardVelocity = OldHorizontalVelocity.ProjectOnToNormal(GetHorizontalForward(InUp));
		const FVector OldSideVelocity = OldHorizontalVelocity - OldForwardVelocity;

		// Then we calculate the new forward and side velocities separately
		// The side velocity is simply interpolated towards 0, so that we will eventually only travel in the horizontal forward direction
		const FVector NewForwardVelocity = GetHorizontalForward(InUp) * InNewForwardSpeed;
		const FVector NewSideVelocity = Math::VInterpTo(OldSideVelocity, FVector::ZeroVector, InDeltaTime, InSideSpeedDeceleration);
		const FVector NewHorizontalVelocity = NewForwardVelocity + NewSideVelocity;

		// We then remove the old horizontal velocity, and add the new one instead
		const FVector OldVerticalVelocity = InVelocity - OldHorizontalVelocity;
		
		InVelocity = OldVerticalVelocity + NewHorizontalVelocity;
	}
}