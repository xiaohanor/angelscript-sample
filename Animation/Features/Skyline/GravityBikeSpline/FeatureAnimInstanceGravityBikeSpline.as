UCLASS(Abstract)
class UFeatureAnimInstanceGravityBikeSpline : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGravityBikeSpline Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGravityBikeSplineAnimData AnimData;

	UGravityBikeSplinePlayerComponent PlayerComp;
	AGravityBikeSpline GravityBike;
	UGravityBikeBladePlayerComponent BladeComp;

	/**
	 * FGravityBikePlayerAnimationData
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bIsPassenger;

	/**
	 * FGravityBikeAnimationData
	 */
	// Speed in the forward direction
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;
	// Turning speed, used for determining how much to lean in turns, -1 to 1
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float AngularSpeed;
	// Actual angular velocity relative to spline, not clamped, normalized or smoothed
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator AngularVelocity;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsThrottling;
	// Steering, smoothed, -1 to 1
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float Steering;

	// 0 -> 1 of how much the boost is charged
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float BoostAlpha;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bIsBoosting;

	// How much the bike is leaning
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

	// The mesh visually hit the floor
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

	/**
	 * FGravityBikeBladeAnimationData
	 */
	// Do we currently have the gravity blade in our hand? (waiting to throw)
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bEquippedGravityBlade;
	// Are we currently throwing the gravity blade?
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bThrowGravityBlade;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bFinisheThrowGravityBlade;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bBladeGrappling = false;
	// What side are we throwing on? Left is -1, right is 1
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float BladeThrowSide = 0;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    bool bIsChangingGravity;
	// 0 -> 1 of how far we are through the gravity change transition
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float GravityChangeAlpha;
	// How long the gravity change transition will last
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float GravityChangeDuration;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FVector PreviousGravityDirection;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    FVector NewGravityDirection;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
    float RotateDirection;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGravityChangeLandedThisFrame;

	/**
	 * Phone Variables
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPhoneActive;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFaceRecognitionActive;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPressing;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D PhoneThumbBlendSpace;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D PhoneHandBlendSpace;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float PhoneAdditiveAlpha;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		auto NewFeature = GetFeatureAsClass(ULocomotionFeatureGravityBikeSpline);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PlayerComp = UGravityBikeSplinePlayerComponent::Get(Player);
		GravityBike = PlayerComp.GravityBike;

		BladeComp = UGravityBikeBladePlayerComponent::Get(GravityBikeBlade::GetPlayer());
		PhoneAdditiveAlpha = 1.0;
		bFinisheThrowGravityBlade = false;
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

		UpdateBikePlayerAnimData();
		UpdateBikeAnimData();
		UpdateBladeAnimData();

		if(Player.IsZoe())
			UpdatePhoneData();
	}

	private void UpdateBikePlayerAnimData()
	{
		const FGravityBikeSplinePlayerAnimationData& BikePlayerAnimData = PlayerComp.AnimationData;

		bIsPassenger = BikePlayerAnimData.bIsPassenger;
	}

	private void UpdateBikeAnimData()
	{
		const FGravityBikeSplineAnimationData& BikeAnimData = GravityBike.AnimationData;

		Speed = BikeAnimData.Speed;
		AngularSpeed = BikeAnimData.AngularSpeed;
		AngularVelocity = BikeAnimData.AngularVelocity;
		bIsThrottling = BikeAnimData.bIsThrottling;
		Steering = BikeAnimData.Steering;

		BoostAlpha = BikeAnimData.BoostAlpha;
		bIsBoosting = BikeAnimData.bIsBoosting;

		RollAngle = BikeAnimData.RollAngle;
		RollVelocity = BikeAnimData.RollVelocity;

		PitchAngle = BikeAnimData.PitchAngle;
		PitchVelocity = BikeAnimData.PitchVelocity;

		bFloorImpact = (GravityBike.AnimationData.FloorImpactFrame == Time::FrameNumber);
		FloorImpactImpulse = GravityBike.AnimationData.FloorImpactImpulse;
		bLeftGround = (GravityBike.AnimationData.LeaveGroundFrame == Time::FrameNumber);
		bStartedJumpThisFrame = (GravityBike.AnimationData.JumpFrame == Time::FrameNumber);
		
		const FVector BikeWorldVelocity = GravityBike.ActorVelocity;
		BikeWorldVerticalVelocity = BikeWorldVelocity.DotProduct(-GravityBike.GetGravityDir());

		if (GravityBike.IsAirborne.Get() || bFloorImpact)
			HeightMhBlendValue = (BikeWorldVerticalVelocity / 10);
		else
			HeightMhBlendValue = (BikeWorldVerticalVelocity / 20);

		if (bFloorImpact)
		{
			LandingHeightBlendSpaceValue = BikeAnimData.FloorImpactImpulse / 10;
			
			// PrintToScreenScaled("HeightMhBlendValue: " + HeightMhBlendValue, 3.f, Scale = 3.f);
		}

	
		#if EDITOR
			/*
			Print("BikeWorldVerticalVelocity: " + BikeWorldVerticalVelocity, 0.f);
			PrintToScreen(f"{HeightMhBlendValue=}");
			Print("RollAngle: " + RollAngle, 0.f);
			PrintToScreen(f"{RotateDirection=}");
			PrintToScreen(f"{Steering=}");
			PrintToScreen(f"{Speed=}");
			PrintToScreen(f"{StickyThrottle=}");
			PrintToScreen(f"{ImmediateThrottle=}");
			PrintToScreen(f"{LandingHeightBlendSpaceValue=}");
			PrintToScreen(f"{bIsChangingGravity=}");
			PrintToScreen(f"{NewGravityDirection=}");
			PrintToScreen(f"{GravityChangeAlpha=}");
			PrintToScreen(f"{bGravityChangeLandedThisFrame=}");
			PrintToScreen(f"{bFloorImpact=}");
			PrintToScreen(f"{AngularSpeed=}");
			PrintToScreen(f"{AngularVelocity=}");
			PrintToScreen(f"{bIsBoosting=}");
			PrintToScreen(f"{BoostAlpha=}");
			PrintToScreen(f"{BoostDuration=}");
			PrintToScreen(f"{WheelieAngle=}");
			PrintToScreen(f"{TiltVelocity=}");
			PrintToScreen(f"{PreviousGravityDirection=}");
			PrintToScreen(f"{bIsChangingGravity=}");
			*/
		#endif
	}

	private void UpdateBladeAnimData()
	{
		const FGravityBikeBladeAnimationData& BladeAnimData = BladeComp.AnimationData;

		if(Player.IsMio())
		{
			bEquippedGravityBlade = BladeAnimData.bEquippedGravityBlade;
			bThrowGravityBlade = BladeAnimData.bThrowGravityBlade;
			BladeThrowSide = BladeAnimData.BladeThrowSide;
			if (bEquippedGravityBlade)
				bBladeGrappling = true;
		}


		bIsChangingGravity = BladeAnimData.bIsChangingGravity;
		
		GravityChangeAlpha = BladeAnimData.GravityChangeAlpha;
		GravityChangeDuration = BladeAnimData.GravityChangeDuration;

		PreviousGravityDirection = BladeAnimData.PreviousGravityDirection;
		NewGravityDirection = BladeAnimData.NewGravityDirection;

		RotateDirection = BladeAnimData.RotateDirection;
		bGravityChangeLandedThisFrame = BladeAnimData.LandedFrame == Time::FrameNumber;
	}

	private void UpdatePhoneData()
	{
		ASkylineNewPhone Phone = Cast<ASkylineNewPhone>(GravityBikeSpline::Phone::GetPlayerComponent().Phone);
		bPhoneActive = Phone != nullptr;
		bFaceRecognitionActive = false;
		bIsPressing = false;

		if(bPhoneActive)
		{
			PhoneAdditiveAlpha = 0.5;
			bIsPressing = Phone.bIsPressing;
			bFaceRecognitionActive = Cast<USkylinePhoneGameFaceRecognitionWidget>(Phone.CurrentGame) != nullptr;
			FVector2D BlendSpaceValue = Phone.CursorPosition.Value / Phone.CursorBounds; //-1 to 1
			PhoneHandBlendSpace = BlendSpaceValue;

			BlendSpaceValue.Y = (-BlendSpaceValue.Y + 1) / 2; //Remap (-1 to 1) to (0 to 1)
			BlendSpaceValue.Y *= 3; //Remap to (0 to 3)
			PhoneThumbBlendSpace = BlendSpaceValue;
		}
		else
			PhoneAdditiveAlpha = 1.0;
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
    UFUNCTION()
    void AnimNotify_FinishedThrow()
    {
		bBladeGrappling = false;
	}

}
