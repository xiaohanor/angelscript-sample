UCLASS(Abstract)
class UFeatureAnimInstanceFantasyOtterJump : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFantasyOtterJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFantasyOtterJumpAnimData AnimData;

	// Add Custom Variables Here

	ATundraPlayerOtterActor Otter;
	// Since the otter mesh is on a seperate actor that is attached to player, we must use this variable instead of just Player
	AHazePlayerCharacter ParentPlayer;

	UPlayerMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromSwimming;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	bool bReachedApex;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPerformApexTrick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ChestPositionAlpha;

	// Range: [-1, 1] to be used as values in a blendspace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D RotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float JumpTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int ApexTrickPicker;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float JumpRotation;

	// Settings

	// Hip pitch rotation
	const float HIP_PITCH_MAX = 85 / (90 / 2.0);
	const float HIP_PITCH_MIN = -85;
	const float HIP_PITCH_INTERPSPEED_SWIMMING = 5;
	const float HIP_PITCH_INTERPSPEED_STOP = 0.3;

	const float ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED = 4; // Interp speed for the upper body
	const float ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED = 3; // Interp speed for the lower body
	const float ADDITIVE_BANKING_LOWERBODY_BREASTSTROKE_INTERP_SPEED = 10; // Interp speed for the lower body during breast stroke
	const float ADDITIVE_BANK_ALPHA_INTERPSPEED = 1.5; // When going from Mh -> Swim, how fast should the banking activate


	//Variables not exposed to ABP
	FVector MovementInput;
	FVector LocalVelocity;
	FVector PreviousVelocity;
	

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		// Get components here...

		Otter = Cast<ATundraPlayerOtterActor>(HazeOwningActor);
		ParentPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);

		MoveComp = UPlayerMovementComponent::Get(ParentPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFantasyOtterJump NewFeature = GetFeatureAsClass(ULocomotionFeatureFantasyOtterJump);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		JumpTime = 0;

		bCameFromSwimming = GetPrevLocomotionAnimationTag() == "UnderwaterSwimming" || GetPrevLocomotionAnimationTag() == "Swimming" || GetPrevLocomotionAnimationTag() == "SurfaceSwimming";

		const float PreviousHipsPitch = Otter.Mesh.GetSocketTransform(n"Spine4", ERelativeTransformSpace::RTS_Actor).Rotator().Pitch;

		if (bCameFromSwimming && PreviousHipsPitch <= 40)
		{
			HipsRotation.Pitch = (GetAnimFloatParam (n"SwimPitchRotationFloat", bConsume = true, DefaultValue = PreviousHipsPitch)) + 40;
			JumpTime = 0.5;
		}
		else
		{
			HipsRotation.Pitch = GetAnimFloatParam (n"SwimPitchRotationFloat", bConsume = true, DefaultValue = PreviousHipsPitch);
		}

		JumpRotation = FRotator::MakeFromXZ(ParentPlayer.GetActorLocalVelocity().GetSafeNormal(), FVector::RightVector).Pitch / (90 / 2.0);
		
		ChestPositionAlpha = 1;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		bool bFromSwimming = GetPrevLocomotionAnimationTag() == "UnderwaterSwimming" || GetPrevLocomotionAnimationTag() == "Swimming" || GetPrevLocomotionAnimationTag() == "SurfaceSwimming";
		if(bFromSwimming)
			return 0.2;

		return 0.0;
	}
	
	// float JumpRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		MovementInput = MoveComp.SyncedMovementInputForAnimationOnly;
		PreviousVelocity = LocalVelocity;
		LocalVelocity = ParentPlayer.GetActorLocalVelocity();
		JumpTime = JumpTime + DeltaTime;

		JumpRotation = Math::FInterpTo(JumpRotation,
				FRotator::MakeFromXZ(ParentPlayer.GetActorLocalVelocity().GetSafeNormal(), FVector::RightVector).Pitch  / (90 / 2.0),
				DeltaTime,
				0
			);

		// TODO (ns): DO not use Player.ActorVelocity.Z, this should check if Y/A on the controller is pressed
		bWantsToMove = MovementInput != FVector::ZeroVector || Math::Abs(LocalVelocity.Z) > 100;
		

		CalculateUnderWaterHipRotation(DeltaTime);

		ChestPositionAlpha = Math::FInterpTo(ChestPositionAlpha, 0, DeltaTime, 2);

		

		

		if (CheckValueChangedAndSetBool (bReachedApex, ((PreviousVelocity.Z > 100) && LocalVelocity.Z <= 100), EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			if (bReachedApex)
			{
				bPerformApexTrick = true;
				ApexTrickPicker = Math::RandRange(0,2);
			}
			else
			{
				bPerformApexTrick = false;
			}
		}
		else
		{
			bPerformApexTrick = false;
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

		if (LocomotionAnimationTag == n"UnderwaterSwimming" || LocomotionAnimationTag == n"UnderwaterSwimming" || LocomotionAnimationTag == n"AirMovement" || LocomotionAnimationTag == n"Landing")
		SetAnimFloatParam (n"SwimPitchRotationFloat", HipsRotation.Pitch);
		
		if (bCameFromSwimming && LocomotionAnimationTag == n"AirMovement")
		{
			SetAnimBoolParam (n"JumpFromWater", true);
			SetAnimFloatParam (n"SwimJumpBSValue", JumpTime * -1);
		}
	}

		/**
	 * Calcualte the hips rotation based on the players velocity
	 */
	void CalculateUnderWaterHipRotation(float DeltaTime) 
	{

		// Calculate Pitch (Up / Down)
		ParentPlayer.OverrideGravityDirection(FVector(0, 0, -1), FInstigator(this, n"ForcedDirection"));

		float PitchTarget;
		float PitchInterpSpeed;

		// Use different interp speeds depending if the player is moving or returning back to Mh
		// if (bWantsToMove)
		// {
			
		// 	// Player has input and is currently swimming
		// 	PitchTarget = Math::Clamp(FRotator::MakeFromXZ(LocalVelocity, FVector::UpVector).Pitch, HIP_PITCH_MIN, HIP_PITCH_MAX);
		// 	PitchInterpSpeed = HIP_PITCH_INTERPSPEED_SWIMMING;
		// }
		// else
		// {
		// 	// Player doesn't have any input and is about to go back to Mh
		// 	PitchTarget = 0;
		// 	PitchInterpSpeed = HIP_PITCH_INTERPSPEED_STOP;
		// }

		PitchTarget = -160;
		if(bReachedApex)
		{
			PitchInterpSpeed = Math::FInterpTo(HIP_PITCH_INTERPSPEED_STOP, HIP_PITCH_INTERPSPEED_STOP * 100, DeltaTime, 1);
		}
		else
		{
			PitchInterpSpeed = HIP_PITCH_INTERPSPEED_STOP;
		}
	
		

		// Interpolate the rotation	

		const float NewRotation = Math::FInterpTo(HipsRotation.Pitch, PitchTarget, DeltaTime, PitchInterpSpeed);

		// Update the rotation rate
		
		RotationRate.Y = Math::Clamp(((NewRotation - HipsRotation.Pitch) / DeltaTime / 100), -1.0, 1.0);


		HipsRotation.Pitch = NewRotation;

		// Calculate the rotation rate
		const float YawTargetRotationRate = Math::Clamp(MoveComp.GetMovementYawVelocity(false) / 200, -1.0, 1.0);

		float YawInterpSpeed = 10;

		// Update the rotation rate
		RotationRate.X = Math::FInterpTo(RotationRate.X, YawTargetRotationRate, DeltaTime, YawInterpSpeed);
		

		// Do a double interp on the hip rotations, interpolating it towards the already interpolated RotationRate.X
		HipsRotation.Roll = Math::FInterpTo(HipsRotation.Roll, RotationRate.X, DeltaTime, 5);

	}
}
