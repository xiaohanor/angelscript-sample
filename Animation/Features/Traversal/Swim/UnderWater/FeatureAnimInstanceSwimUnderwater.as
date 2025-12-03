UCLASS(Abstract)
class UFeatureAnimInstanceSwimUnderwater : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSwimUnderwater Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSwimUnderwaterAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerSwimmingAnimData SwimmingAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D LowerBodyAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D UpperBodyAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	FVector2D LowerBodyBreastStrokeAdditiveBankingValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive Banking")
	float AdditiveBankingAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Paddle")
	bool bPlayPaddle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Paddle")
	bool bPaddleLeftHandForward;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Paddle")
	float PaddleStopTimer;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Paddle")
	bool bCanExitPaddle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	// Range: [-1, 1] to be used as values in a blendspace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D RotationRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayBreastStroke;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInBreastStroke;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HorizontalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float NoInputTimer;

	float PaddleAlphaTarget;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Paddle")
	bool bInPaddle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Paddle")
	float PaddleAlpha;

	// TODO: This is for the Otter, remove this as soon as it has it's own mesh/animinstace
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDashingThisFrame;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bAscendInPlace;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDescendInPlace;

	// Components
	UPlayerMovementComponent MoveComp;
	UPlayerSwimmingComponent SwimComponent;

	// Variables not exposed to the ABP
	FTimerHandle PaddleTimerHandle;
	float BreastStrokeTimer;
	FVector MovementInput;
	FVector LocalVelocity;
	// bool bInPaddle;

	// Settings

	// Hip pitch rotation
	const float HIP_PITCH_MAX = 85;
	const float HIP_PITCH_MIN = -85;
	const float HIP_PITCH_INTERPSPEED_SWIMMING = 1.5;
	const float HIP_PITCH_INTERPSPEED_STOP = 0.5;

	const float ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED = 4;			   // Interp speed for the upper body
	const float ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED = 3;			   // Interp speed for the lower body
	const float ADDITIVE_BANKING_LOWERBODY_BREASTSTROKE_INTERP_SPEED = 10; // Interp speed for the lower body during breast stroke
	const float ADDITIVE_BANK_ALPHA_INTERPSPEED = 1.5;					   // When going from Mh -> Swim, how fast should the banking activate

	// Paddle
	const float PADDLE_THRESHOLD = 0.65;	   // On a scale of [0, 1]
	const float PADDLE_ACTIVATE_TIMER = 0.4;   // How many seconds does the player need to be over  the threshold for paddle to activate
	const float PADDLE_DEACTIVATE_TIMER = 0.5; // How many seconds does the player need to be below the threshold for paddle to deactivate

	// Breast Stroke
	const float BREAST_STROKE_INTERVAL = 3;	   // How often should breast stroke trigger? (in seconds)
	const float BREAST_STROKE_MIN_SPEED = 200; // What is the minimum speed needed for a breast stroke to trigger

	// ---------------------------------------------------------------------
	// 							 Initialize
	// ---------------------------------------------------------------------

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSwimUnderwater NewFeature = GetFeatureAsClass(ULocomotionFeatureSwimUnderwater);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Get components
		MoveComp = UPlayerMovementComponent::Get(Player);
		SwimComponent = UPlayerSwimmingComponent::GetOrCreate(Player);

		const FTransform HipsTransform = Player.Mesh.GetSocketTransform(n"Hips");
		const float Dot = HipsTransform.TransformVectorNoScale(Player.ActorUpVector).DotProduct(Player.ActorUpVector);
		const float PreviousHipsPitch = Math::RadiansToDegrees(Math::Acos(Dot));

		HipsRotation.Pitch = GetAnimFloatParam(n"SwimPitchRotationFloat", bConsume = true, DefaultValue = PreviousHipsPitch);

		RotationRate = FVector2D::ZeroVector;

		NoInputTimer = 0;

		bInPaddle = false;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (PrevLocomotionAnimationTag == n"AirMovement" || PrevLocomotionAnimationTag == n"Jump")
			return 0.4;

		if (PrevLocomotionAnimationTag == n"ApexDive")
			return 0.5;

		return 0.2;
	}

	// ---------------------------------------------------------------------
	// 							 Update
	// ---------------------------------------------------------------------

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		SwimmingAnimData = SwimComponent.AnimData;
		MovementInput = MoveComp.SyncedMovementInputForAnimationOnly;
		HorizontalVelocity = Player.ActorHorizontalVelocity.Size();
		VerticalVelocity = Player.ActorVerticalVelocity.Z;
		LocalVelocity = Player.GetActorLocalVelocity();
		Speed = LocalVelocity.Size();

		// TODO: This is for the Otter, remove this as soon as it has it's own mesh/animinstace
		bDashingThisFrame = SwimComponent.AnimData.bDashingThisFrame;

		// if(bDashingThisFrame)
		// {
		// 	bInBreastStroke = false;
		// }

		// TODO (ns): DO not use Player.ActorVelocity.Z, this should check if Y/A on the controller is pressed
		bWantsToMove = MovementInput != FVector::ZeroVector || (SwimmingAnimData.VerticalMovementScale > SMALL_NUMBER || SwimmingAnimData.VerticalMovementScale < 0); // Math::Abs(LocalVelocity.Z) > 100;

		// Calculate the hips rotation
		CalculateUnderWaterHipRotation(DeltaTime);

		// Additive Banking
		if (bWantsToMove && AdditiveBankingAlpha != 1)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 1, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED);
		else if (!bWantsToMove && Speed < 50 && AdditiveBankingAlpha != 0)
			AdditiveBankingAlpha = Math::FInterpTo(AdditiveBankingAlpha, 0, DeltaTime, ADDITIVE_BANK_ALPHA_INTERPSPEED * 0.5);

		UpperBodyAdditiveBankingValues.X = Math::FInterpTo(UpperBodyAdditiveBankingValues.X, RotationRate.X, DeltaTime, ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED);
		LowerBodyAdditiveBankingValues.X = Math::FInterpTo(LowerBodyAdditiveBankingValues.X, UpperBodyAdditiveBankingValues.X * AdditiveBankingAlpha, DeltaTime, ADDITIVE_BANKING_LOWERBODY_INTERP_SPEED);
		LowerBodyBreastStrokeAdditiveBankingValues.X = Math::FInterpTo(UpperBodyAdditiveBankingValues.X, RotationRate.X, DeltaTime, ADDITIVE_BANKING_UPPERBODY_INTERP_SPEED);

		const float UpDownRatio = HipsRotation.Pitch / 90;
		UpperBodyAdditiveBankingValues.Y = UpDownRatio;
		LowerBodyAdditiveBankingValues.Y = UpDownRatio;
		LowerBodyBreastStrokeAdditiveBankingValues.Y = UpDownRatio;

		PaddleAlpha = Math::FInterpTo(PaddleAlpha, PaddleAlphaTarget, DeltaTime, 2);

		bAscendInPlace = SwimmingAnimData.VerticalMovementScale > SMALL_NUMBER && (Math::Abs(MoveComp.HorizontalVelocity.X) < 1 && Math::Abs(MoveComp.HorizontalVelocity.Y) < 1);

		bDescendInPlace = SwimmingAnimData.VerticalMovementScale < 0 && (Math::Abs(MoveComp.HorizontalVelocity.X) < 1 && Math::Abs(MoveComp.HorizontalVelocity.Y) < 1);

		if (bWantsToMove)
		{
			// Breast stroke logic
			bPlayBreastStroke = false;
			float BreastStrokeTimerMultiplier = Speed / 500;
			BreastStrokeTimer += DeltaTime * BreastStrokeTimerMultiplier;

			if (BreastStrokeTimer > BREAST_STROKE_INTERVAL && Speed > BREAST_STROKE_MIN_SPEED && !bPlayPaddle)
			{
				bPlayBreastStroke = true;
				BreastStrokeTimer = 0;
				bPaddleLeftHandForward = GetAnimBoolParam(n"UnderwaterPaddleLeftHandForward", bConsume = false, bDefaultValue = false);
				bInBreastStroke = true;
			}

			// Turning logic
			const bool bAboveTurningThreshold = Math::Abs(RotationRate.X) > PADDLE_THRESHOLD;

			if (bPlayPaddle)
			{
				// Timer to stop paddling
				if (!bAboveTurningThreshold && !PaddleTimerHandle.IsTimerActive())
					PaddleTimerHandle = Timer::SetTimer(this, n"DisablePaddle", PADDLE_DEACTIVATE_TIMER);

				else if (bAboveTurningThreshold)
					PaddleTimerHandle.ClearTimer();
			}
			else
			{

				// Timer to start paddling
				if (bAboveTurningThreshold && !PaddleTimerHandle.IsTimerActive())
					PaddleTimerHandle = Timer::SetTimer(this, n"EnablePaddle", PADDLE_ACTIVATE_TIMER);

				else if (!bAboveTurningThreshold)
					PaddleTimerHandle.ClearTimer();
			}
		}
		if (PaddleStopTimer > 0)
		{
			PaddleStopTimer = Math::FInterpTo(PaddleStopTimer, 0, DeltaTime, 2);
		}
	}

	// ---------------------------------------------------------------------
	// 						AnimNotifies / Events
	// ---------------------------------------------------------------------

	// Triggered once you leave the BreastStroke state
	UFUNCTION()
	void AnimNotify_LeftBreastStroke()
	{
		BreastStrokeTimer = 0;
		PaddleTimerHandle.ClearTimer();
		bInBreastStroke = false;
		// DisablePaddle();
	}

	UFUNCTION()
	void AnimNotify_LeftPaddleAndBreastStroke()
	{
		bInBreastStroke = false;
	}

	// UFUNCTION()
	// void AnimNotify_EnterPadde()
	// {
	// 	bInPaddle = true;
	// }

	// UFUNCTION()
	// void AnimNotify_ExitPadde()
	// {
	// 	bInPaddle = false;
	// }

	UFUNCTION()
	void AnimNotify_IsNotInUnderwaterPaddle()
	{
		bInPaddle = false;
	}

	UFUNCTION()
	void AnimNotify_HasStartedUnderwaterPaddle()
	{
		bInPaddle = true;
	}

	UFUNCTION()
	void EnablePaddle()
	{
		bPlayPaddle = true;
		// bPaddleLeftHandForward = GetAnimBoolParam (n"UnderwaterPaddleLeftHandForward", bConsume = false, bDefaultValue =  false);
		bInPaddle = true;
	}

	UFUNCTION()
	void DisablePaddle()
	{
		bPlayPaddle = false;
		// bPaddleLeftHandForward = GetAnimBoolParam (n"UnderwaterPaddleLeftHandForward", bConsume = false, bDefaultValue =  false);
		PaddleStopTimer = 1;
	}

	// ---------------------------------------------------------------------
	// 			 Custom functions for various calculations
	// ---------------------------------------------------------------------

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
			// if (bAscendInPlace || bDescendInPlace)
			// {
			// 	PitchTarget = Math::Clamp(FRotator::MakeFromXZ(LocalVelocity, FVector::UpVector).Pitch, HIP_PITCH_MIN, HIP_PITCH_MAX);
			// 	PitchInterpSpeed = HIP_PITCH_INTERPSPEED_SWIMMING * 0.5;
			// }
			// else
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
		if (DeltaTime > 0.0)
			RotationRate.Y = Math::FInterpTo(RotationRate.Y, (Math::Clamp(((NewRotation - HipsRotation.Pitch) / DeltaTime / 100), -1.0, 1.0)), DeltaTime, 2);

		HipsRotation.Pitch = NewRotation;

		// Calculate Yaw (Left / Right)

		// Calculate the rotation rate
		const float YawTargetRotationRate = Math::Clamp(MoveComp.GetMovementYawVelocity(false) / 200, -1.0, 1.0);

		// Use different interp speeds depending if we're going into our out of a turn
		float YawInterpSpeed = 4.5; // Going out of a turn
		if (Math::Abs(RotationRate.X) < Math::Abs(YawTargetRotationRate))
			YawInterpSpeed = 7.5;	// Leaning into a turn

		// Update the rotation rate
		RotationRate.X = Math::FInterpTo(RotationRate.X, YawTargetRotationRate, DeltaTime, YawInterpSpeed);

		// Do a double interp on the hip rotations, interpolating it towards the already interpolated RotationRate.X
		HipsRotation.Roll = Math::FInterpTo(HipsRotation.Roll, RotationRate.X, DeltaTime, YawInterpSpeed);
	}
}
