UCLASS(Abstract)
class UFeatureAnimInstanceFantasyOtterAirMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFantasyOtterAirMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFantasyOtterAirMovementAnimData AnimData;

	ATundraPlayerOtterActor Otter;
	// Since the otter mesh is on a seperate actor that is attached to player, we must use this variable instead of just Player
	AHazePlayerCharacter ParentPlayer;

	UPlayerMovementComponent MoveComp;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;

	// Physical Animation
	UHazePhysicalAnimationComponent PhysAnimComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;	

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	FQuat CachedActorRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float FallVelocity;

	// Range: [-1, 1] to be used as values in a blendspace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D RotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumpingFromSwimming;

	// Swim Rotation Settings

	// Hip pitch rotation
	const float HIP_PITCH_MAX = 85;
	const float HIP_PITCH_MIN = -85;
	const float HIP_PITCH_INTERPSPEED_SWIMMING = 5;
	const float HIP_PITCH_INTERPSPEED_STOP = 0.3;

	const float ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED = 4; // Interp speed for the upper body
	const float ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED = 3; // Interp speed for the lower body
	const float ADDITIVE_BANKING_LOWERBODY_BREASTSTROKE_INTERP_SPEED = 10; // Interp speed for the lower body during breast stroke
	const float ADDITIVE_BANK_ALPHA_INTERPSPEED = 1.5; // When going from Mh -> Swim, how fast should the banking activate


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
		ULocomotionFeatureFantasyOtterAirMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureFantasyOtterAirMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		CachedActorRotation = HazeOwningActor.ActorQuat;

		const float PreviousHipsPitch = Otter.Mesh.GetSocketTransform(n"Spine4", ERelativeTransformSpace::RTS_Actor).Rotator().Pitch;

		HipsRotation.Pitch = GetAnimFloatParam (n"SwimPitchRotationFloat", bConsume = true, DefaultValue = PreviousHipsPitch);
		BlendspaceValues.Y = GetAnimFloatParam (n"SwimJumpBSValue", true, -1);

		bJumpingFromSwimming = GetAnimBoolParam (n"JumpFromWater", true, false);

		// Physical Animation stuff
		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);

		PhysAnimComp.ApplyProfileAsset(this, Feature.PhysAnimProfile, BlendTime = 0.2);


	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return 0.2;
    }


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;

		Speed = MoveComp.Velocity.Size();
		if (CheckValueChangedAndSetBool(bWantsToMove, !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero()))
		{
			if (!bWantsToMove)
			{
				// Called when user let's go of the stick
				StoppingSpeed = Speed;
			}
		}
		
		// Banking
		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime, Feature.MaxTurnSpeed);

		//CalculateUnderWaterHipRotation(DeltaTime);

		HipsRotation.Pitch = Math::FInterpTo(HipsRotation.Pitch, -40, DeltaTime, 2);

		BlendspaceValues.Y = Math::FInterpTo(BlendspaceValues.Y, ParentPlayer.GetActorLocalVelocity().Z / 1000, DeltaTime, 0.1);
		BlendspaceValues.X = Banking;

		FallVelocity = MoveComp.VerticalVelocity.Z / MoveComp.TerminalVelocity;// - MoveComp.PreviousVerticalVelocity.Z;

		


		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{

		return true;

		// if (LocomotionAnimationTag != n"Movement")
		// {
		// 	return true;
		// }

		// if (TopLevelGraphRelevantStateName == n"ExitToMovement" && !bWantsToMove)
		// {
		// 	return true;
		// }
		
		// if (TopLevelGraphRelevantStateName == n"ExitToMm" && bWantsToMove)
		// {
		// 	return true;
		// }

		// return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (LocomotionAnimationTag == n"UnderwaterSwimming" || LocomotionAnimationTag == n"SurfaceSwimming" || LocomotionAnimationTag == n"AirMovement" || LocomotionAnimationTag == n"Landing")
			SetAnimFloatParam (n"SwimPitchRotationFloat", HipsRotation.Pitch);

		if(LocomotionAnimationTag == n"Movement")
		{
			if(TopLevelGraphRelevantStateName == n"ExitToMovement" && bWantsToMove)
			{
				SetAnimBoolParam(n"SkipMovementStart", true);
				SetAnimBlendTimeToMovement(HazeOwningActor, 0);
			}
			
		}

		PhysAnimComp.ClearProfileAsset(this);
	
	}

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

		PitchTarget = 0;
		PitchInterpSpeed = 30;


		//PitchInterpSpeed = HIP_PITCH_INTERPSPEED_STOP;
		
	


		// Interpolate the rotation	

		const float NewRotation = Math::FInterpTo(HipsRotation.Pitch, PitchTarget, DeltaTime, PitchInterpSpeed);

		// Update the rotation rate
		
		RotationRate.Y = Math::Clamp(((NewRotation - HipsRotation.Pitch) / DeltaTime / 100), -1.0, 1.0);


		HipsRotation.Pitch = NewRotation;

		// Calculate the rotation rate
		const float YawTargetRotationRate = Math::Clamp(MoveComp.GetMovementYawVelocity(false) / 200, -1.0, 1.0);

		float YawInterpSpeed = 10;

		// Update the rotation rate
		// RotationRate.X = Math::FInterpTo(RotationRate.X, YawTargetRotationRate, DeltaTime, YawInterpSpeed);
		

		// Do a double interp on the hip rotations, interpolating it towards the already interpolated RotationRate.X
		// HipsRotation.Roll = Math::FInterpTo(HipsRotation.Roll, RotationRate.X, DeltaTime, 5);

	}
}
