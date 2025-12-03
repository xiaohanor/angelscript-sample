UCLASS(Abstract)
class UFeatureAnimInstanceFantasyOtterSwimUnderwater : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFantasyOtterSwimUnderwater Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFantasyOtterSwimUnderwaterAnimData AnimData;

	// Add Custom Variables Here

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
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MovementSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	// Range: [-1, 1] to be used as values in a blendspace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D RotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D QuickRotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float NoInputTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsDashing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashingThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY()
	FRuntimeFloatCurve WavyCurveSize;

	UPROPERTY()
	float ChestPositionAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float WavyAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TailWavyAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float WavyActivity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float WavySpeed = 5;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float WavyFreq = 30;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float WavySize = 20;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StartMovingWaveMultiplier;

	bool bIsMoving;

	bool bStartedToMove;

	bool bAscendInPlace;

	bool bDescendInPlace;

	bool bAscendingOrDescendingInPlace;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HipDisplacementAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HeadRollCounterValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLaunchObject;

	// Components
	UPlayerMovementComponent MoveComp;
	UTundraPlayerOtterSwimmingComponent SwimComponent;

	// Physical Animation
	UHazePhysicalAnimationComponent PhysAnimComp;

	// Variables not exposed to the ABP
	FTimerHandle PaddleTimerHandle;
	float BreastStrokeTimer;
	FVector MovementInput;
	FVector LocalVelocity;

	// Settings

	// Hip pitch rotation
	const float HIP_PITCH_MAX = 85;
	const float HIP_PITCH_MIN = -85;
	const float HIP_PITCH_INTERPSPEED_SWIMMING = 5;
	const float HIP_PITCH_INTERPSPEED_STOP = 0.5;

	const float ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED = 4;			   // Interp speed for the upper body
	const float ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED = 3;			   // Interp speed for the lower body
	const float ADDITIVE_BANKING_LOWERBODY_BREASTSTROKE_INTERP_SPEED = 10; // Interp speed for the lower body during breast stroke
	const float ADDITIVE_BANK_ALPHA_INTERPSPEED = 1.5;					   // When going from Mh -> Swim, how fast should the banking activate

	ATundraPlayerOtterActor Otter;
	// Since the otter mesh is on a seperate actor that is attached to player, we must use this variable instead of just Player
	AHazePlayerCharacter ParentPlayer;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{

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
		ULocomotionFeatureFantasyOtterSwimUnderwater NewFeature = GetFeatureAsClass(ULocomotionFeatureFantasyOtterSwimUnderwater);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		// Reset values

		const float PreviousHipsPitch = Otter.Mesh.GetSocketTransform(n"Spine4", ERelativeTransformSpace::RTS_Actor).Rotator().Pitch;

		HipsRotation.Pitch = GetAnimFloatParam(n"SwimPitchRotationFloat", bConsume = true, DefaultValue = PreviousHipsPitch);

		RotationRate = FVector2D::ZeroVector;

		NoInputTimer = 0;

		// Physical Animation stuff
		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);

		PhysAnimComp.ApplyProfileAsset(this, Feature.PhysAnimProfile, BlendTime = 0.2);

		ChestPositionAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.5;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		SwimmingAnimData = SwimComponent.AnimData;
		MovementInput = MoveComp.SyncedMovementInputForAnimationOnly;
		LocalVelocity = ParentPlayer.GetActorLocalVelocity();
		Speed = LocalVelocity.Size();

		MovementSpeed = Speed / 1200;

		// bIsDashing = SwimComponent.AnimData.bDashingThisFrame;

		// TODO (ns): DO not use Player.ActorVelocity.Z, this should check if Y/A on the controller is pressed
		bWantsToMove = MovementInput != FVector::ZeroVector || (SwimmingAnimData.VerticalMovementScale > SMALL_NUMBER || SwimmingAnimData.VerticalMovementScale < 0);// || Math::Abs(LocalVelocity.Z) > 100;

		// Calculate the hips rotation
		CalculateUnderWaterHipRotation(DeltaTime);

		// Additive Banking
		if (bWantsToMove && AdditiveBankingAlpha != 1)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 1, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED);
		else if (!bWantsToMove && Speed < 50 && AdditiveBankingAlpha != 0)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 0, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED * 0.5);

		// UpperBodyAdditiveBankingValues.X = Math::FInterpTo(UpperBodyAdditiveBankingValues.X, RotationRate.X, DeltaTime, ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED);
		// LowerBodyAdditiveBankingValues.X = Math::FInterpTo(LowerBodyAdditiveBankingValues.X, UpperBodyAdditiveBankingValues.X * AdditiveBankingAlpha, DeltaTime, ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED);

		FRotator DeltaRotation = (ParentPlayer.ActorRotation - CachedActorRotation).Normalized;

		CachedActorRotation = ParentPlayer.ActorRotation;

		if (Math::Abs(RotationRate.X) > 0.1)
		{
			DeltaYaw = Math::Clamp((Math::FInterpTo(DeltaYaw, DeltaRotation.Yaw / DeltaTime / 60, DeltaTime, 8)), -1, 1);
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
		{
			HeadRollSpring.SpringTo(DeltaYaw, 20, 0.7, DeltaTime * TurnValueMultiplier);

			UpperBodyRollSpring.SpringTo(DeltaYaw, 10, 0.7, DeltaTime);

			LowerBodyRollSpring.SpringTo(DeltaYaw, 5, 0.3, DeltaTime);

			TailRollSpring.SpringTo(Math::Clamp(LowerBodyRollSpring.Value, -1.0, 1.0), 20, 0.2, DeltaTime);
		}
		else
		{
			HeadRollSpring.SpringTo(DeltaYaw, 50, 0.7, DeltaTime * TurnValueMultiplier);

			UpperBodyRollSpring.SpringTo(DeltaYaw, 5, 0.7, DeltaTime);

			LowerBodyRollSpring.SpringTo(Math::Clamp(UpperBodyRollSpring.Value, -1.0, 1.0), 15, 0.1, DeltaTime);

			TailRollSpring.SpringTo(Math::Clamp(LowerBodyRollSpring.Value, -1.0, 1.0), 20, 0.2, DeltaTime);

			// Experiment that doesn't work without a PhysProfile
			// TailRollSpring.SpringTo(Math::FInterpTo(DeltaYaw * 1000, DeltaYaw, DeltaTime, 3), 80, 0.5, DeltaTime);
		}

		UpperBodyAdditiveBankingValues.X = UpperBodyRollSpring.Value;

		LowerBodyAdditiveBankingValues.X = LowerBodyRollSpring.Value;

		TailAdditiveBankingValues.X = TailRollSpring.Value;

		HeadAdditiveBankingValues.X = HeadRollSpring.Value;

		// Banking = CalculateAnimationBankingValue(ParentPlayer, CachedActorRotation, DeltaTime, Feature.MaxTurnSpeed);

		// End Additive Banking

		if (bWantsToMove == false)
		{
			NoInputTimer = Math::FInterpTo(NoInputTimer, 1.0, DeltaTime, 0.25);
			PhysAnimComp.SetBoneSimulated(n"Tail1", true, Alpha = 1, bAllBodiesBelow = true, bIncludeSelf = true, BlendTime = 0.2);
		}
		else
		{
			NoInputTimer = 0;
			PhysAnimComp.SetBoneSimulated(n"Tail1", true, Alpha = 0, bAllBodiesBelow = true, bIncludeSelf = true, BlendTime = 0.2);
		}

		if (CheckValueChangedAndSetBool(bIsDashing, SwimmingAnimData.bDashingThisFrame, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			bDashingThisFrame = true;
		}
		else
		{
			bDashingThisFrame = false;
		}
		
		bAscendInPlace = SwimmingAnimData.VerticalMovementScale > SMALL_NUMBER && (Math::Abs(MoveComp.HorizontalVelocity.X) < 1 && Math::Abs(MoveComp.HorizontalVelocity.Y) < 1);

		bDescendInPlace = SwimmingAnimData.VerticalMovementScale < 0 && (Math::Abs(MoveComp.HorizontalVelocity.X) < 1 && Math::Abs(MoveComp.HorizontalVelocity.Y) < 1);

		

		if (CheckValueChangedAndSetBool(bIsMoving, bWantsToMove, EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			bStartedToMove = true;
			StartMovingWaveMultiplier = 5;
		}
		else
		{
			bStartedToMove = false;
		}

		StartMovingWaveMultiplier = Math::FInterpTo(StartMovingWaveMultiplier, 1, DeltaTime, 3);// - (Math::FInterpTo((Math::Abs(HipsRotation.Roll)), 0, DeltaTime, 3));

		

		if (CheckValueChangedAndSetBool(bAscendingOrDescendingInPlace, (bAscendInPlace||bDescendInPlace), EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			Target = 1.2;		
		}
		
		Target = Math::FInterpTo(Target, 0, DeltaTime, 1);

		ChestPositionAlpha = Math::FInterpTo(ChestPositionAlpha, 1, DeltaTime, 1);


		HipDisplacementAlpha = Math::FInterpTo(HipDisplacementAlpha, Target, DeltaTime, 1);

		

		WavyActivity = Math::Clamp(MovementSpeed + Math::Abs(HipsRotation.Roll*0.7), 0.02, 1);
		WavySpeed = 15 * WavyActivity  - Math::Abs(HipsRotation.Roll * 5);
		WavySize = WavyCurveSize.GetFloatValue(MovementSpeed);

		//WavySize = 15 + Math::Max((10 * Math::Abs(HipsRotation.Roll)) - (10 * Math::Abs(RotationRate.Y)), 0);// + HipDisplacementAlpha;
		
	
		if (Math::Abs(MoveComp.HorizontalVelocity.X) > 5 || Math::Abs(MoveComp.HorizontalVelocity.Y) > 5)
		{
			WavyAlpha = Math::FInterpTo(WavyAlpha, bWantsToMove ? 1 : 0, DeltaTime, 7);
		}
		else
		{
			WavyAlpha = Math::FInterpTo(WavyAlpha, bWantsToMove ? 1 : 0, DeltaTime, 2);
		}

		if (LowestLevelGraphRelevantStateName == n"Start" || LowestLevelGraphRelevantStateName == n"LaunchObjectUp")
		{
			TailWavyAlpha = Math::FInterpTo(0, 0.2, DeltaTime, 0.2);
		}
		else
		
		{
			TailWavyAlpha = Math::FInterpTo(TailWavyAlpha, bWantsToMove ? 1 : 0, DeltaTime, 1);
		}
		
		
		HeadRollCounterValue = Math::FInterpTo(Math::FInterpTo(HeadRollCounterValue, 0, DeltaTime, 3), HipsRotation.Roll * -1, DeltaTime, 5);


		
	}

	float Target;

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

		PhysAnimComp.ClearProfileAsset(this);
	}

	/**
	 * Calcualte the hips rotation based on the players velocity
	 */
	void CalculateUnderWaterHipRotation(float DeltaTime)
	{

		// Calculate Pitch (Up / Down)

		float PitchTarget = 0;
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
		// bRotatingIntoTurn = (Math::Abs(RotationRate.X) < Math::Abs(YawTargetRotationRate));

		float YawInterpSpeed = 104.5; // Going out of a turn
		// if (Math::Abs (RotationRate.X) < Math::Abs(YawTargetRotationRate))
		if (bRotatingIntoTurn)
			YawInterpSpeed = 7.5; // Leaning into a turn

		// Update the rotation rate
		RotationRate.X = Math::FInterpTo(RotationRate.X, YawTargetRotationRate, DeltaTime, YawInterpSpeed);

		// Do a double interp on the hip rotations, interpolating it towards the already interpolated RotationRate.X
		HipsRotation.Roll = Math::FInterpTo(HipsRotation.Roll, RotationRate.X, DeltaTime, 5);
	}
}
