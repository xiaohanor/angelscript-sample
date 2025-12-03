UCLASS(Abstract)
class UFeatureAnimInstanceFantasyOtterSwimSurface : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFantasyOtterSwimSurface Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFantasyOtterSwimSurfaceAnimData AnimData;

	// Add Custom Variables Here

		//Components

	UPlayerMovementComponent MoveComp;
	UTundraPlayerOtterSwimmingComponent SwimComponent;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MovementSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTundraPlayerOtterSwimmingAnimData SwimmingAnimData;

	FRotator CachedActorRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float DeltaYaw;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D HeadAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D LowerBodyAdditiveBankingValues;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D UpperBodyAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D TailAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	float AdditiveBankingAlpha;

	bool bRotatingIntoTurn;

	FHazeAcceleratedFloat UpperBodyRollSpring;

	FHazeAcceleratedFloat LowerBodyRollSpring;

	FHazeAcceleratedFloat HeadRollSpring;

	FHazeAcceleratedFloat TailRollSpring;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Pitch")
	FVector2D HeadAdditivePitchValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Pitch")
	FVector2D LowerBodyAdditivePitchValues;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Pitch")
	FVector2D UpperBodyAdditivePitchValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Pitch")
	FVector2D TailAdditivePitchValues;

	FHazeAcceleratedFloat HeadPitchSpring;

	FHazeAcceleratedFloat UpperBodyPitchSpring;

	FHazeAcceleratedFloat LowerBodyPitchSpring;

	FHazeAcceleratedFloat TailPitchSpring;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	// Range: [-1, 1] to be used as values in a blendspace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D RotationRate;

	// TODO: This is for the Otter, remove this as soon as it has it's own mesh/animinstace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashingThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D QuickRotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float NoInputTimer;


	//Variables not exposed to ABP

	FVector MovementInput;
	FVector LocalVelocity;
	
	//Physical Animation
	UHazePhysicalAnimationComponent PhysAnimComp;

	// Settings

	// Hip pitch rotation
	const float HIP_PITCH_MAX = 85;
	const float HIP_PITCH_MIN = -85;
	const float HIP_PITCH_INTERPSPEED_SWIMMING = 5;
	const float HIP_PITCH_INTERPSPEED_STOP = 0.5;

	const float ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED = 4; // Interp speed for the upper body
	const float ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED = 3; // Interp speed for the upper body
	const float ADDITIVE_BANK_ALPHA_INTERPSPEED = 1.5; // When going from Mh -> Swim, how fast should the banking activate

	ATundraPlayerOtterActor Otter;
	// Since the otter mesh is on a seperate actor that is attached to player, we must use this variable instead of just Player
	AHazePlayerCharacter ParentPlayer;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		// Get components here...

		Otter = Cast<ATundraPlayerOtterActor>(HazeOwningActor);
		ParentPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);

		if (Otter == nullptr)
			return;


		MoveComp = UPlayerMovementComponent::Get(ParentPlayer);
		SwimComponent = UTundraPlayerOtterSwimmingComponent::GetOrCreate(ParentPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFantasyOtterSwimSurface NewFeature = GetFeatureAsClass(ULocomotionFeatureFantasyOtterSwimSurface);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		// Reset values
		
		HipsRotation = FRotator::ZeroRotator;
		RotationRate = FVector2D::ZeroVector;

		NoInputTimer = 0;

		//Physical Animation stuff
		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);

		PhysAnimComp.ApplyProfileAsset(this, Feature.PhysAnimProfile, BlendTime = 0.2);
		

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

		// HipsRotation = FRotator::ZeroRotator;
		// RotationRate = FVector2D::ZeroVector;

		SwimmingAnimData = SwimComponent.AnimData;
		MovementInput = MoveComp.SyncedMovementInputForAnimationOnly;
		LocalVelocity = ParentPlayer.GetActorLocalVelocity();
		Speed = LocalVelocity.Size();

		MovementSpeed = Speed / 1100;

		//bIsDashing = SwimComponent.AnimData.bDashingThisFrame;
		
		// TODO (ns): DO not use Player.ActorVelocity.Z, this should check if Y/A on the controller is pressed
		bWantsToMove = MovementInput != FVector::ZeroVector || Math::Abs(LocalVelocity.Z) > 100;


		// Calculate the hips rotation
		CalculateUnderWaterHipRotation(DeltaTime);

		// Additive Banking
		if (bWantsToMove && AdditiveBankingAlpha != 1)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 1, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED);
		else if (!bWantsToMove && Speed < 50 && AdditiveBankingAlpha != 0)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 0, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED * 0.5);
		
		//UpperBodyAdditiveBankingValues.X = Math::FInterpTo(UpperBodyAdditiveBankingValues.X, RotationRate.X, DeltaTime, ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED);
		//LowerBodyAdditiveBankingValues.X = Math::FInterpTo(LowerBodyAdditiveBankingValues.X, UpperBodyAdditiveBankingValues.X * AdditiveBankingAlpha, DeltaTime, ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED);
		
		FRotator DeltaRotation = (ParentPlayer.ActorRotation - CachedActorRotation).Normalized;

		CachedActorRotation = ParentPlayer.ActorRotation;


		if (Math::Abs(RotationRate.X)> SMALL_NUMBER)
		{
			DeltaYaw = Math::Clamp((Math::FInterpTo(DeltaYaw, DeltaRotation.Yaw  / DeltaTime / 60, DeltaTime, 8)), -1, 1);
		}
		else
		{
			DeltaYaw = Math::Clamp((Math::FInterpTo(DeltaYaw, 0, DeltaTime, 8)), -1, 1);
		}

		
		const float UpDownRatio = HipsRotation.Pitch / 90;
		UpperBodyAdditiveBankingValues.Y = UpDownRatio;
		LowerBodyAdditiveBankingValues.Y = UpDownRatio;
		TailAdditiveBankingValues.Y = UpDownRatio;

		float TurnValueMultiplier = bRotatingIntoTurn ? 1 : 2;
		
		if (bRotatingIntoTurn)
		{HeadRollSpring.SpringTo(DeltaYaw, 30, 0.7, DeltaTime * TurnValueMultiplier);

		UpperBodyRollSpring.SpringTo(DeltaYaw, 20, 0.5, DeltaTime);

		LowerBodyRollSpring.SpringTo(DeltaYaw, 30, 0.3, DeltaTime);

		TailRollSpring.SpringTo(Math::Clamp(LowerBodyRollSpring.Value , -1.0, 1.0), 10, 0.2, DeltaTime);
		}
		else
		{
		HeadRollSpring.SpringTo(DeltaYaw, 50, 0.7, DeltaTime * TurnValueMultiplier);

		UpperBodyRollSpring.SpringTo(DeltaYaw, 30, 0.5, DeltaTime);

		LowerBodyRollSpring.SpringTo(DeltaYaw, 80, 0.3, DeltaTime);

		TailRollSpring.SpringTo(Math::Clamp(LowerBodyRollSpring.Value , -1.0, 1.0), 20, 0.2, DeltaTime);
		}


		UpperBodyAdditiveBankingValues.X = UpperBodyRollSpring.Value;
		
		LowerBodyAdditiveBankingValues.X = LowerBodyRollSpring.Value;

		TailAdditiveBankingValues.X = TailRollSpring.Value;

		HeadAdditiveBankingValues.X = HeadRollSpring.Value;

	

		// End Additive Banking 

		if (bWantsToMove == false)
		{
			NoInputTimer = Math::FInterpTo(NoInputTimer, 1.0, DeltaTime, 0.25);
		
		}
			else
		{
			NoInputTimer = 0;
		}

		if (CheckValueChangedAndSetBool (bIsDashing, SwimmingAnimData.bDashingThisFrame, EHazeCheckBooleanChangedDirection::FalseToTrue))
			{
				bDashingThisFrame = true;
			}
		else
			{
				bDashingThisFrame = false;
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

		if (LocomotionAnimationTag == n"UnderwaterSwimming" || LocomotionAnimationTag == n"Jump")
		SetAnimFloatParam (n"SwimPitchRotationFloat", HipsRotation.Pitch);

		PhysAnimComp.ClearProfileAsset(this);
	}

	/**
	 * Calcualte the hips rotation based on the players velocity
	 */
	void CalculateUnderWaterHipRotation(float DeltaTime) 
	{

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


		HeadPitchSpring.SpringTo(RotationRate.Y, 30, 0.9, DeltaTime);

		UpperBodyPitchSpring.SpringTo(RotationRate.Y, 15, 0.5, DeltaTime);

		LowerBodyPitchSpring.SpringTo(RotationRate.Y, 10, 0.3, DeltaTime);

		TailPitchSpring.SpringTo(LowerBodyAdditivePitchValues.Y, 10, 0.2, DeltaTime);

		HeadAdditivePitchValues.Y = HeadPitchSpring.Value;

		UpperBodyAdditivePitchValues.Y = UpperBodyPitchSpring.Value;
		
		LowerBodyAdditivePitchValues.Y = LowerBodyPitchSpring.Value;

		TailAdditivePitchValues.Y = TailPitchSpring.Value;


		// Calculate Yaw (Left / Right)

		// Calculate the rotation rate
		const float YawTargetRotationRate = Math::Clamp(MoveComp.GetMovementYawVelocity(false) / 200, -1.0, 1.0);
		
		// Use different interp speeds depending if we're going into our out of a turn
		bRotatingIntoTurn = (Math::Abs(YawTargetRotationRate) > 0.1 && (Math::Abs(RotationRate.X) < Math::Abs(YawTargetRotationRate)));
		// OLD CALCULATION
		//bRotatingIntoTurn = (Math::Abs(RotationRate.X) < Math::Abs(YawTargetRotationRate));

		float YawInterpSpeed = 104.5; // Going out of a turn
		//if (Math::Abs (RotationRate.X) < Math::Abs(YawTargetRotationRate))
		if (bRotatingIntoTurn)
			YawInterpSpeed = 7.5; // Leaning into a turn
		
		// Update the rotation rate
		RotationRate.X = Math::FInterpTo(RotationRate.X, YawTargetRotationRate, DeltaTime, YawInterpSpeed);
		

		// Do a double interp on the hip rotations, interpolating it towards the already interpolated RotationRate.X
		HipsRotation.Roll = Math::FInterpTo(HipsRotation.Roll, RotationRate.X, DeltaTime, 5);

		
		
	}
}
