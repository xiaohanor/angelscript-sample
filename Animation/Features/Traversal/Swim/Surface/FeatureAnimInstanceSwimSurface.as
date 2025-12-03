UCLASS(Abstract)
class UFeatureAnimInstanceSwimSurface : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSwimSurface Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSwimSurfaceAnimData AnimData;

	//Components

	UPlayerMovementComponent MoveComp;
	UPlayerSwimmingComponent SwimComponent;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerSwimmingAnimData SwimmingAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D LowerBodyAdditiveBankingValues;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D UpperBodyAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	float AdditiveBankingAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	// Range: [-1, 1] to be used as values in a blendspace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D RotationRate;

	// TODO: This is for the Otter, remove this as soon as it has it's own mesh/animinstace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashingThisFrame;

	//Variables not exposed to ABP

	FVector MovementInput;
	FVector LocalVelocity;

	// Settings

	// Hip pitch rotation
	const float HIP_PITCH_MAX = 85;
	const float HIP_PITCH_MIN = -85;
	const float HIP_PITCH_INTERPSPEED_SWIMMING = 3;
	const float HIP_PITCH_INTERPSPEED_STOP = 1.5;

	const float ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED = 4; // Interp speed for the upper body
	const float ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED = 3; // Interp speed for the upper body
	const float ADDITIVE_BANK_ALPHA_INTERPSPEED = 1.5; // When going from Mh -> Swim, how fast should the banking activate


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSwimSurface NewFeature = GetFeatureAsClass(ULocomotionFeatureSwimSurface);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here



		//Get Components

		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
		SwimComponent = UPlayerSwimmingComponent::GetOrCreate(Player);

		// Reset values
		HipsRotation = FRotator::ZeroRotator;
		RotationRate = FVector2D::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (PrevLocomotionAnimationTag == n"UnderwaterSwimming")
		{
			return 1.0;
		}

		else
		{
			return 0.2;
		}
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		SwimmingAnimData = SwimComponent.AnimData;
		MovementInput = MoveComp.SyncedMovementInputForAnimationOnly;
		LocalVelocity = Player.GetActorLocalVelocity();
		Speed = LocalVelocity.Size();

		// TODO: (ns) Remove this once otter is in
		bDashingThisFrame = SwimmingAnimData.bDashingThisFrame;


		// TODO (ns): DO not use Player.ActorVelocity.Z, this should check if Y/A on the controller is pressed
		bWantsToMove = MovementInput != FVector::ZeroVector || Math::Abs(LocalVelocity.Z) > 100;

		//Calculate hips rotation
		CalculateHipRotation(DeltaTime);

		// Additive Banking
		if (bWantsToMove && AdditiveBankingAlpha != 1)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 1, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED);
		else if (!bWantsToMove && Speed < 50 && AdditiveBankingAlpha != 0)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 0, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED * 0.5);
		
		UpperBodyAdditiveBankingValues.X = Math::FInterpTo(UpperBodyAdditiveBankingValues.X, RotationRate.X, DeltaTime, ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED);
		LowerBodyAdditiveBankingValues.X = Math::FInterpTo(LowerBodyAdditiveBankingValues.X, UpperBodyAdditiveBankingValues.X * AdditiveBankingAlpha, DeltaTime, ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED);
		
		const float UpDownRatio = HipsRotation.Pitch / 90;
		UpperBodyAdditiveBankingValues.Y = UpDownRatio;
		LowerBodyAdditiveBankingValues.Y = UpDownRatio;
		// End Additive Banking 

	

		
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

		if (LocomotionAnimationTag == n"UnderwaterSwimming")
		SetAnimFloatParam (n"SwimPitchRotationFloat", HipsRotation.Pitch);

	}

	// ---------------------------------------------------------------------
	// 			 Custom functions for various calculations
	// ---------------------------------------------------------------------

	/**
	 * Calcualte the hips rotation based on the players velocity
	 */
	void CalculateHipRotation(float DeltaTime) 
	{
		if(DeltaTime < KINDA_SMALL_NUMBER)
			return;

		// Calculate Pitch (Up / Down)

		float PitchTarget;
		float PitchInterpSpeed;

		// Use different interp speeds depending if the player is moving or returning back to Mh
		if (bWantsToMove)
		{
			
			// Player has input and is currently swimming
			PitchTarget = Math::Clamp(FRotator::MakeFromXZ(LocalVelocity, FVector::UpVector).Pitch, HIP_PITCH_MIN, HIP_PITCH_MAX);
			PitchInterpSpeed = HIP_PITCH_INTERPSPEED_SWIMMING;
		}
		else
		{
			// Player doesn't have any input and is about to go back to Mh
			PitchTarget = 0;
			PitchInterpSpeed = HIP_PITCH_INTERPSPEED_STOP;
		}

		// Interpolate the rotation		
		const float NewRotation = Math::FInterpTo(HipsRotation.Pitch, PitchTarget, DeltaTime, PitchInterpSpeed);

		// Update the rotation rate
		RotationRate.Y = Math::Clamp(((NewRotation - HipsRotation.Pitch) / DeltaTime / 100), -1.0, 1.0);

		HipsRotation.Pitch = NewRotation;



		// Calculate Yaw (Left / Right)

		// Calculate the rotation rate
		const float YawTargetRotationRate = Math::Clamp(MoveComp.GetMovementYawVelocity(false) / 200, -1.0, 1.0);
		
		// Use different interp speeds depending if we're going into our out of a turn
		float YawInterpSpeed = 4.5; // Going out of a turn
		if (Math::Abs (RotationRate.X) < Math::Abs(YawTargetRotationRate))
			YawInterpSpeed = 7.5; // Leaning into a turn
		
		// Update the rotation rate
		RotationRate.X = Math::FInterpTo(RotationRate.X, YawTargetRotationRate, DeltaTime, YawInterpSpeed);
		
		// Do a double interp on the hip rotations, interpolating it towards the already interpolated RotationRate.X
		HipsRotation.Roll = Math::FInterpTo(HipsRotation.Roll, RotationRate.X, DeltaTime, YawInterpSpeed);
	}

}
