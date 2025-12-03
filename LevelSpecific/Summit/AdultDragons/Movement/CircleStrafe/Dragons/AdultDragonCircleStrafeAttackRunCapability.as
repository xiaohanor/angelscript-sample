class UAdultDragonCircleStrafeAttackRunCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonStrafeComponent StrafeComp;
	UAdultDragonCircleStrafeComponent CircleStrafeComp;
	UAdultDragonSplineFollowManagerComponent SplineFollowComp;
	UAdultDragonSplineFollowManagerComponent OtherSplineFollowComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	AAdultDragonBoundarySpline BoundarySpline;

	ASummitAdultDragonCircleStrafeManager StrafeManager;

	UAdultDragonStrafeSettings StrafeSettings;

	const float FlightSpeed = 6000.0;
	const float InitialRotationSpeed = 2.0;

	const float DeltaAlphaMaxRubberbandingThreshold = 0.1;
	const float MaxRubberbandingSpeed = 5000.0;

	FHazeAcceleratedQuat AccRotation;

	float RightOffset;
	float UpOffset;

	FRotator InitialDeltaRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);

		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		StrafeComp = UAdultDragonStrafeComponent::Get(Player);
		CircleStrafeComp = UAdultDragonCircleStrafeComponent::Get(Player);
		SplineFollowComp = UAdultDragonSplineFollowManagerComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();

		BoundarySpline = TListedActors<AAdultDragonBoundarySpline>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (StrafeManager == nullptr)
			return false;

		if (StrafeManager.CurrentState != ESummitAdultDragonCircleStrafeState::AttackRun)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (StrafeManager.CurrentState != ESummitAdultDragonCircleStrafeState::AttackRun)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Flying, this, EInstigatePriority::Normal);
		AccRotation.SnapTo(FQuat::Identity);
		Player.ApplyCameraSettings(StrafeComp.StrafeCameraSettings, 0.5, this, EHazeCameraPriority::Medium);

		devCheck(SplineFollowComp.CurrentSplineFollowData.IsSet(), f"Attempting to do attack run but {Player.Name} has no spline to follow");
		FAdultDragonSplineFollowData SplinePos = SplineFollowComp.CurrentSplineFollowData.Value;
		FVector DeltaToPlayer = Player.ActorLocation - SplinePos.WorldLocation;
		UpOffset = SplinePos.WorldUpVector.DotProduct(DeltaToPlayer);
		RightOffset = SplinePos.WorldRightVector.DotProduct(DeltaToPlayer);

		InitialDeltaRotation = Player.ActorRotation - SplinePos.WorldRotation.Rotator();

		DragonComp.AimingInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
		Player.ClearCameraSettingsByInstigator(this);

		DragonComp.AimingInstigators.RemoveSingleSwap(this);

		CircleStrafeComp.bHasReachedEndOfAttackRunSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (StrafeManager == nullptr)
			StrafeManager = CircleStrafeComp.StrafeManager;

		if (OtherSplineFollowComp == nullptr)
			OtherSplineFollowComp = UAdultDragonSplineFollowManagerComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FAdultDragonSplineFollowData SplinePos = SplineFollowComp.CurrentSplineFollowData.Value;

				FVector2D MovementInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
				FRotator InputRotation = FRotator(MovementInput.X * StrafeSettings.MaxTurningOffset.Pitch, MovementInput.Y * StrafeSettings.MaxTurningOffset.Yaw, 0);
				StrafeComp.InputRotation = InputRotation;
				AccRotation.AccelerateTo(InputRotation.Quaternion(), StrafeSettings.StrafeTurningDuration, DeltaTime);

				InitialDeltaRotation = Math::RInterpTo(InitialDeltaRotation, FRotator::ZeroRotator, DeltaTime, InitialRotationSpeed);
				FQuat TargetRotation = SplinePos.WorldRotation * AccRotation.Value * InitialDeltaRotation.Quaternion();
				Movement.SetRotation(TargetRotation);

				float RubberbandingSpeed = GetRubberbandingSpeed();
				float TotalSpeed = FlightSpeed + RubberbandingSpeed;
				FVector FrameDelta = Player.ActorForwardVector * TotalSpeed * DeltaTime;
				float SplineDeltaDistance = FrameDelta.DotProduct(SplinePos.WorldForwardVector);
				CircleStrafeComp.bHasReachedEndOfAttackRunSpline = SplinePos.HasReachedEndOfSpline(SplineDeltaDistance);
				float RightDeltaDistance = FrameDelta.DotProduct(SplinePos.WorldRightVector);
				float UpDeltaDistance = FrameDelta.DotProduct(SplinePos.WorldUpVector);

				RightOffset += RightDeltaDistance;
				UpOffset += UpDeltaDistance;

				FVector UpOffsetVector = SplinePos.WorldUpVector * UpOffset;
				FVector RightOffsetVector = SplinePos.WorldRightVector * RightOffset;
				FVector TargetLocation = SplinePos.WorldLocation + UpOffsetVector + RightOffsetVector;
				TargetLocation = BoundarySpline.GetClampedLocationWithinBoundary(TargetLocation);

				Movement.AddDelta(TargetLocation - Player.ActorLocation);

				TEMPORAL_LOG(Player)
					.Sphere("Circle Strafe Attack Run: Spline Pos", SplinePos.WorldLocation, 500, FLinearColor::DPink, 10)
					.DirectionalArrow("Circle Strafe Attack Run: Up Offset", SplinePos.WorldLocation, UpOffsetVector, 20, 40, FLinearColor::Blue)
					.DirectionalArrow("Circle Strafe Attack Run: Right Offset", SplinePos.WorldLocation, RightOffsetVector, 20, 40, FLinearColor::Green)
					.Value("Circle Strafe Attack Run: Initial Delta Rotation", InitialDeltaRotation)
					.Value("Circle Strafe Attack Run: Rubberbanding Speed", RubberbandingSpeed);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(AdultDragonLocomotionTags::AdultDragonFlying);
		}
	}

	float GetRubberbandingSpeed() const
	{
		float RubberBandingSpeed = 0.0;

		FAdultDragonSplineFollowData SplinePos = SplineFollowComp.CurrentSplineFollowData.Value;
		FAdultDragonSplineFollowData OtherPlayerSplinePos = OtherSplineFollowComp.CurrentSplineFollowData.Value;

		float SplineLength = SplinePos.SplineLength;
		float CurrentSplineDistance = SplinePos.CurrentSplineDistance;
		float SplineAlpha = CurrentSplineDistance / SplineLength;

		float OtherPlayerSplineLength = OtherPlayerSplinePos.SplineLength;
		float OtherPlayerCurrentSplineDistance = OtherPlayerSplinePos.CurrentSplineDistance;
		float OtherPlayerSplineAlpha = OtherPlayerCurrentSplineDistance / OtherPlayerSplineLength;

		float DeltaAlpha = OtherPlayerSplineAlpha - SplineAlpha;
		float PercentOfMaxDelptaAlpha = Math::Abs(DeltaAlpha) / DeltaAlphaMaxRubberbandingThreshold;

		RubberBandingSpeed = Math::Sign(DeltaAlpha) * PercentOfMaxDelptaAlpha * MaxRubberbandingSpeed;
		RubberBandingSpeed = Math::Clamp(RubberBandingSpeed, -MaxRubberbandingSpeed, MaxRubberbandingSpeed);

		return RubberBandingSpeed;
	}
};