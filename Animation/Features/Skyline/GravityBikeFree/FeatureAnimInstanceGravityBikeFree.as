UCLASS(Abstract)
class UFeatureAnimInstanceGravityBikeFree : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGravityBikeFree Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGravityBikeFreeAnimData AnimData;

	UGravityBikeFreeDriverComponent DriverComp;
	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;

	/**
	 * Speed in the forward direction
	 * Range is 0 to 1
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SpeedAlpha;
	/**
	 * Turning speed, used for determining how much to lean in turns
	 * Range is -1 to 1
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float AngularSpeedAlpha;

	// 0 -> 1 of how much the boost is charged
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float BoostAlpha;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bIsBoosting;

	// How much the bike is leaning left/right
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float RollAngle;
	// How fast the bike lean is changing
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float RollVelocity;

	// How much the bike is tilted up/down
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float PitchAngle;
	// How fast the bike tilt is changing
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float PitchVelocity;

	// We landed on the ground this frame
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bFloorImpact;

	// How hard did we hit the ground? Will always be a positive value.
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float FloorImpactImpulse;

	// We became airborne this frame
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bLeftGround;

	// We jumped (or just visually jumped, without any impulse)
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bStartedJumpThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BikeWorldVerticalVelocity;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float HeightMhBlendValue;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float LandingHeightBlendSpaceValue;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		auto NewFeature = GetFeatureAsClass(ULocomotionFeatureGravityBikeFree);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		GravityBike = DriverComp.GetGravityBike();
		MoveComp = GravityBike.MoveComp;
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2f;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		UpdateBikeAnimData();

#if EDITOR
		// PrintToScreen(f"{SpeedAlpha=}");
		// PrintToScreen(f"{AngularSpeedAlpha=}");

		// PrintToScreen(f"{bIsBoosting=}");
		// PrintToScreen(f"{BoostAlpha=}");

		// PrintToScreen(f"{RollAngle=}");
		// PrintToScreen(f"{RollVelocity=}");

		// PrintToScreen(f"{PitchAngle=}");
		// PrintToScreen(f"{PitchVelocity=}");

		// PrintToScreen(f"{bFloorImpact=}");
#endif
	}

	private void UpdateBikeAnimData()
	{
		SpeedAlpha = GravityBike.AnimationData.SpeedAlpha;
		AngularSpeedAlpha = GravityBike.AnimationData.AngularSpeedAlpha;

		BoostAlpha = bIsBoosting ? GravityBike.AnimationData.BoostAlpha : 0.0;
		bIsBoosting = GravityBike.AnimationData.bIsBoosting;

		RollAngle = GravityBike.AnimationData.RollAngle;
		RollVelocity = GravityBike.AnimationData.RollVelocity;

		PitchAngle = GravityBike.AnimationData.PitchAngle;
		PitchVelocity = GravityBike.AnimationData.PitchVelocity;

		bFloorImpact = (GravityBike.AnimationData.FloorImpactFrame == Time::FrameNumber);
		FloorImpactImpulse = GravityBike.AnimationData.FloorImpactImpulse;
		bLeftGround = (GravityBike.AnimationData.LeaveGroundFrame == Time::FrameNumber);
		bStartedJumpThisFrame = (GravityBike.AnimationData.JumpFrame == Time::FrameNumber);
		Print("bStartedJumpThisFrame: " + bStartedJumpThisFrame, 0.f);

		BikeWorldVerticalVelocity = MoveComp.VerticalSpeed;
		
		if (GravityBike.IsAirborne.Get() || bFloorImpact)
			HeightMhBlendValue = (BikeWorldVerticalVelocity / 10);
		else
			HeightMhBlendValue = (BikeWorldVerticalVelocity / 20);

		if (bFloorImpact)
		{
			LandingHeightBlendSpaceValue = HeightMhBlendValue;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
