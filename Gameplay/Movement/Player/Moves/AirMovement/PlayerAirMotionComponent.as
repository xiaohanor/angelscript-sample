struct FAirMotionVelocityConstraint
{
	FVector BaseVelocity;

	bool bOverrideLateralSpeed = false;
	float LateralSpeed = 0.0;
	float LateralAcceleration = 0.0;
}

struct FAirMotionWeakenedControl
{
	float Multiplier = 1.0;
	float Timer = 0.0;
	float Duration = 0.0;
	float BlendInDuration = 0.0;
	float BlendOutDuration = 0.0;
	bool bShouldClearWhenNotAirborne = false;
	bool bWeakenFacingRotation = true;
}


class UPlayerAirMotionComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPlayerAirMotionSettings Settings;
	UPlayerMovementComponent MoveComp;

	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerLadderComponent LadderComp;
	UPlayerWallRunComponent WallrunComp;
	UPlayerWallScrambleComponent WallScrambleComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerSwingComponent SwingComp;

	FPlayerAirMotionData AirMotionData;
	FPlayerAirMotionAnimData AnimData;

	private TArray<FAirMotionWeakenedControl> AirControlWeakens;
	TInstigated<FAirMotionVelocityConstraint> VelocityConstraint;

	FVector PreAirMotionVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerAirMotionSettings::GetSettings(Cast<AHazeActor>(Owner));
		MoveComp = UPlayerMovementComponent::Get(Owner);

		LadderComp = UPlayerLadderComponent::Get(Owner);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Owner);
		WallrunComp = UPlayerWallRunComponent::Get(Owner);
		WallScrambleComp = UPlayerWallScrambleComponent::GetOrCreate(Owner);
		GrappleComp = UPlayerGrappleComponent::Get(Owner);
		SwingComp = UPlayerSwingComponent::Get(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (int i = AirControlWeakens.Num() - 1; i >= 0; --i)
		{
			if(AirControlWeakens[i].bShouldClearWhenNotAirborne
				&& (!MoveComp.IsInAir()
					|| PoleClimbComp.State != EPlayerPoleClimbState::Inactive
						|| LadderComp.State != EPlayerLadderState::Inactive
							|| WallrunComp.State != EPlayerWallRunState::None
								|| WallScrambleComp.Data.State != EPlayerWallScrambleState::None
									|| GrappleComp.Data.GrappleState != EPlayerGrappleStates::Inactive
										|| SwingComp.IsCurrentlySwinging()))
			{
				AirControlWeakens.RemoveAt(i);
			}
			else
			{
				AirControlWeakens[i].Timer += DeltaSeconds;
				if (AirControlWeakens[i].Timer >= AirControlWeakens[i].Duration)
					AirControlWeakens.RemoveAt(i);
			}
		}

		if (AirControlWeakens.Num() == 0)
			SetComponentTickEnabled(false);
	}

	void TemporarilyWeakenAirControl(float Multiplier, float Duration, float BlendInTime = 0, float BlendOutTime = 0, bool bShouldBeClearedWhenNotAirborne = false, bool bWeakenFacingRotation = true)
	{
		FAirMotionWeakenedControl Weaken;
		Weaken.Multiplier = Multiplier;
		Weaken.Duration = Duration;
		Weaken.BlendInDuration = BlendInTime;
		Weaken.BlendOutDuration = BlendOutTime;
		Weaken.bShouldClearWhenNotAirborne = bShouldBeClearedWhenNotAirborne;
		Weaken.bWeakenFacingRotation = bWeakenFacingRotation;

		AirControlWeakens.Add(Weaken);
		SetComponentTickEnabled(true);
	}

	float GetAirControlWeakeningMultiplier(bool bForFacingRotation) const
	{
		float Multiplier = 1.0;
		for (auto& Weaken : AirControlWeakens)
		{
			if (bForFacingRotation && !Weaken.bWeakenFacingRotation)
				continue;

			float WeakenMult = 1.0;
			if (Weaken.Timer < Weaken.BlendInDuration)
			{
				WeakenMult = Math::GetMappedRangeValueClamped(
					FVector2D(0.0, Weaken.BlendInDuration),
					FVector2D(1.0, Weaken.Multiplier),
					Weaken.Timer,
				);
			}
			else if (Weaken.Timer >= Weaken.Duration - Weaken.BlendOutDuration)
			{
				WeakenMult = Math::GetMappedRangeValueClamped(
					FVector2D(Weaken.Duration - Weaken.BlendOutDuration, Weaken.Duration),
					FVector2D(Weaken.Multiplier, 1.0),
					Weaken.Timer,
				);
			}
			else
			{
				WeakenMult = Weaken.Multiplier;
			}

			Multiplier = Math::Min(Multiplier, WeakenMult);
		}

		return Math::Max(Multiplier, 0.0);
	}

	FVector CalculateStandardAirControlVelocity(
		FVector MovementInput,
		FVector PreviousVelocity,
		float DeltaTime,
		float AirControlMultiplier = 1.0,
		float AirMovementSpeedMultiplier = 1.0
	)
	{
		if (VelocityConstraint.IsDefaultValue())
		{
			return CalculateUnconstrainedAirControlVelocity(
				MovementInput, PreviousVelocity, DeltaTime,
				AirControlMultiplier, AirMovementSpeedMultiplier
			);
		}
		else
		{
			return CalculateConstrainedAirControlVelocity(
				MovementInput, PreviousVelocity, DeltaTime,
				AirControlMultiplier, AirMovementSpeedMultiplier
			);
		}
	}

	FVector CalculateConstrainedAirControlVelocity(
		FVector MovementInput,
		FVector PreviousVelocity,
		float DeltaTime,
		float AirControlMultiplier = 1.0,
		float AirMovementSpeedMultiplier = 1.0
	)
	{
		// Velocity in the direction of the constraint is always standardized
		FAirMotionVelocityConstraint Constraint = VelocityConstraint.Get();
		FVector BaseVelocity = Constraint.BaseVelocity;
		FVector ConstraintDirection = BaseVelocity.GetSafeNormal();

		// Normal air control is applied in the non-constrained axis
		FVector AirControl;
		if (Constraint.bOverrideLateralSpeed)
		{
			FVector SidewaysDirection = ConstraintDirection.CrossProduct(MoveComp.WorldUp).GetSafeNormal();
			float SidewaysSpeed = PreviousVelocity.DotProduct(SidewaysDirection);
			float SidewaysInput = MovementInput.DotProduct(SidewaysDirection);

			SidewaysSpeed = Math::FInterpConstantTo(
				SidewaysSpeed, SidewaysInput * Constraint.LateralSpeed,
				DeltaTime, Constraint.LateralAcceleration,
			);

			AirControl = SidewaysDirection * SidewaysSpeed;
		}
		else
		{
			FVector LateralVelocity = PreviousVelocity.ConstrainToPlane(ConstraintDirection);
			FVector LateralInput = MovementInput.ConstrainToPlane(ConstraintDirection);

			AirControl = CalculateUnconstrainedAirControlVelocity(
				LateralInput, LateralVelocity, DeltaTime,
				AirControlMultiplier, AirMovementSpeedMultiplier
			);
		}

		return BaseVelocity + AirControl;
	}

	FVector CalculateUnconstrainedAirControlVelocity(
		FVector MovementInput,
		FVector PreviousVelocity,
		float DeltaTime,
		float AirControlMultiplier = 1.0,
		float AirMovementSpeedMultiplier = 1.0
	)
	{
		float TargetMovementSpeed = Settings.HorizontalMoveSpeed;
		TargetMovementSpeed *= MoveComp.MovementSpeedMultiplier;
		TargetMovementSpeed *= AirMovementSpeedMultiplier;

		float TargetMaximumSpeedBeforeDrag = Settings.MaximumHorizontalMoveSpeedBeforeDrag;
		TargetMaximumSpeedBeforeDrag *= MoveComp.MovementSpeedMultiplier;
		TargetMaximumSpeedBeforeDrag *= AirMovementSpeedMultiplier;

		float InterpSpeed = Settings.HorizontalVelocityInterpSpeed * (AirControlMultiplier * Settings.AirControlMultiplier) * GetAirControlWeakeningMultiplier(false);
		float DragSpeed = Settings.DragOfExtraHorizontalVelocity;

		// Zero input always gives the velocity
	    if (MovementInput.IsNearlyZero())
		{
			float VelocitySize = PreviousVelocity.Size();
			if (VelocitySize > TargetMaximumSpeedBeforeDrag)
				VelocitySize = Math::Max(TargetMaximumSpeedBeforeDrag, VelocitySize - (DragSpeed * DeltaTime));

			return PreviousVelocity.GetSafeNormal() * VelocitySize;
		}

		// Zero velocity returns the the input
		if (PreviousVelocity.IsNearlyZero())
		{
			return Math::VInterpConstantTo(
				PreviousVelocity,
				MovementInput.GetSafeNormal() * TargetMovementSpeed,
				DeltaTime, InterpSpeed);
		}

		const FVector WorldUp = MoveComp.GetWorldUp();
		const float Alignment = MovementInput.VectorPlaneProject(WorldUp).GetSafeNormal().DotProductNormalized(PreviousVelocity.VectorPlaneProject(WorldUp).GetSafeNormal());
		const FVector WorstInputVelocity = MovementInput * TargetMovementSpeed;
		float MovementInputSize = MovementInput.Size();

		float BestInputSpeed = PreviousVelocity.Size();
		if (BestInputSpeed > TargetMaximumSpeedBeforeDrag * MovementInputSize)
		{
			BestInputSpeed = Math::Max(BestInputSpeed - (DragSpeed * DeltaTime), TargetMaximumSpeedBeforeDrag * MovementInputSize);
		}
		else
		{
			BestInputSpeed = Math::Max(BestInputSpeed, TargetMovementSpeed) * MovementInputSize;
		}
		
		FVector BestInputVelocity;
		BestInputVelocity = MovementInput.GetSafeNormal() * BestInputSpeed;

		FVector TargetVelocity = Math::Lerp(WorstInputVelocity, BestInputVelocity, Alignment);
		FVector NewForward = Math::VInterpConstantTo(PreviousVelocity, TargetVelocity, DeltaTime, InterpSpeed); 

		return NewForward;
	}

	void PredictAirMotion(
		float PredictAheadTime,
		FVector InitialVelocity,
		FVector PredictedMovementInput,

		FVector&out OutDeltaMovement,
		FVector&out OutFinalVelocity,
	)
	{
		FVector Position = FVector::ZeroVector;

		FVector WorldUp = MoveComp.WorldUp;
		FVector HorizontalVelocity = InitialVelocity.VectorPlaneProject(WorldUp);
		float VerticalVelocity = InitialVelocity.DotProduct(WorldUp);

		float Gravity = MoveComp.GetGravityForce();

		float Time = 0.0;
		while (Time < PredictAheadTime)
		{
			float DeltaTime = Math::Min(1.0 / 60.0, PredictAheadTime - Time);

			HorizontalVelocity = CalculateStandardAirControlVelocity(
				PredictedMovementInput,
				HorizontalVelocity,
				DeltaTime,
			);

			Position += HorizontalVelocity * DeltaTime;

			float TerminalVelocity = MoveComp.GetTerminalVelocity();
			float NewVerticalVelocity = Math::Max(VerticalVelocity - Gravity * DeltaTime, -TerminalVelocity);

			Position += WorldUp * ((NewVerticalVelocity + VerticalVelocity) * 0.5 * DeltaTime);
			VerticalVelocity = NewVerticalVelocity;

			Time += DeltaTime;
		}

		OutDeltaMovement = Position;
		OutFinalVelocity = HorizontalVelocity + WorldUp * VerticalVelocity;
	}

	//Sets animation data to flag for launch animations to play
	UFUNCTION()
	void FlagForLaunchAnimations(FVector LaunchVelocity)
	{
		AnimData.bPlayerLaunchDetected = true;
		AnimData.LaunchDetectedFrameCount = Time::GetFrameNumber();

		AnimData.InitialLaunchDirection = LaunchVelocity.GetSafeNormal();
		AnimData.InitialLaunchImpulse = LaunchVelocity;
	}
}

struct FPlayerAirMotionData
{
	//If we hit predicted a Swimming volume hit for dive
	FHitResult CurrentPredictedDiveHit;

	bool bDiveDetected = false;

	void ResetData()
	{
		CurrentPredictedDiveHit = FHitResult();
		bDiveDetected = false;
	}
}

struct FPlayerAirMotionAnimData
{
	UPROPERTY()
	bool bHighVelocityLandingDetected = false;

	UPROPERTY()
	bool bPlayerLaunchDetected = false;

	UPROPERTY()
	bool bDiving = false;

	UPROPERTY()
	uint LaunchDetectedFrameCount = 0;
	
	//How fast (as a alpha between -1 ~ 1) are we moving in our forward aligned axis (above our default airmotion speed > a maximum value)
	UPROPERTY()
	float ForwardAlignedVelocityAlpha = 0;

	//How fast (as a alpha between -1 ~ 1) are we moving in our right aligned axis (above our default airmotion speed > a maximum value)
	UPROPERTY()
	float RightAlignedVelocityAlpha = 0;

	//Impulse Vector incase we launched via impulse
	UPROPERTY()
	FVector InitialLaunchImpulse = FVector::ZeroVector;

	//Direction of launch normalized
	UPROPERTY()
	FVector InitialLaunchDirection = FVector::ZeroVector;

	void Reset()
	{
		bHighVelocityLandingDetected = false;
		bDiving = false;

		ResetLaunchData();
	}

	void ResetLaunchData()
	{
		bPlayerLaunchDetected = false;
		LaunchDetectedFrameCount = 0;

		ForwardAlignedVelocityAlpha = 0;
		RightAlignedVelocityAlpha = 0;

		InitialLaunchImpulse = FVector::ZeroVector;
		InitialLaunchDirection = FVector::ZeroVector;
	}
}