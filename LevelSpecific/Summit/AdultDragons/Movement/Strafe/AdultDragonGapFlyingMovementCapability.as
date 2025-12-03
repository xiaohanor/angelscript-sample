class UAdultDragonGapFlyingMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	default DebugCategory = n"AdultDragon";

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonSplineFollowManagerComponent SplineFollowManagerComp;
	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UAdultDragonStrafeComponent StrafeComp;
	UAdultDragonStrafeSettings StrafeSettings;
	AAdultDragonBoundarySpline BoundarySpline;
	FHazeAcceleratedRotator AccelRootRotation;

	bool bFinishTransition;
	bool bTransitionOut;
	// bool bSideFlyingMode;

	FHazeAcceleratedRotator AccSplineRotation;

	FHazeAcceleratedFloat AccSplineVerticalOffset;

	FHazeAcceleratedFloat AccYaw;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();

		StrafeComp = UAdultDragonStrafeComponent::Get(Player);
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);

		BoundarySpline = TListedActors<AAdultDragonBoundarySpline>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DragonComp.bGapFlying)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!SplineFollowManagerComp.CurrentSplineFollowData.IsSet())
			return false;

		if (!DragonComp.GapFlyingData.Value.bUseGapFlyMovement)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!SplineFollowManagerComp.CurrentSplineFollowData.IsSet())
			return true;

		if (!DragonComp.GapFlyingData.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.bIsUsingGapFlyMovement = true;
		Player.ApplyCameraSettings(DragonComp.SideFlyingCameraSettings, DragonComp.GapFlyingData.Value.CameraSettingsBlendTime, this, EHazeCameraPriority::Cutscene);

		Player.PlayCameraShake(DragonComp.ClosingGapCameraShake, this);
		auto SplinePos = SplineFollowManagerComp.CurrentSplineFollowData.Value.GetMostActiveSplinePosition();
		FRotator RotatedSplineRotation = SplinePos.WorldTransform.Rotation.Rotator() + FRotator(0, 0, GetTargetRollAmount());
		FVector SplineToPlayer = Player.ActorLocation - SplinePos.WorldLocation;
		AccSplineVerticalOffset.SnapTo(RotatedSplineRotation.UpVector.DotProduct(SplineToPlayer));
		AccYaw.SnapTo(0);
		AccSplineRotation.SnapTo(Player.ActorRotation);
		DragonComp.AimingInstigators.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bIsUsingGapFlyMovement = false;
		Player.ClearCameraSettingsByInstigator(this);
		Player.StopCameraShakeByInstigator(this);
		DragonComp.bGapFlying = false;
		DragonComp.AimingInstigators.Remove(this);
	}

	float GetTargetRollAmount() const
	{
		return DragonComp.GapFlyingData.Value.RollAmount[Player];
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;
				float ForwardYaw = MovementInput.X * StrafeSettings.MaxTurningOffset.Yaw;

				auto GapflyData = DragonComp.GapFlyingData.Value;

				float RollAmount = GetTargetRollAmount();
				FSplinePosition SplinePos = SplineFollowManagerComp.CurrentSplineFollowData.Value.GetMostActiveSplinePosition();

				FRotator RotatedSplineRotation = SplinePos.WorldTransform.Rotation.Rotator() + FRotator(0, 0, RollAmount);

				float TurningDuration = MovementInput.IsNearlyZero() ? StrafeSettings.StrafeTurnBackDuration : StrafeSettings.StrafeTurningDuration;
				FVector PrevSplineLocation = SplinePos.WorldLocation;

				SplinePos.Move(1000);
				FVector Forward = SplinePos.WorldLocation - PrevSplineLocation;
				FVector AdditionalMoveDelta = FVector::ZeroVector;
				if (GapflyData.bGapFlyMovementMoveToSpline)
				{
					if (AccSplineVerticalOffset.Value > KINDA_SMALL_NUMBER)
					{
						AccSplineVerticalOffset.AccelerateToWithStop(0, 1, DeltaTime, 500);
						FVector TargetLocation = (SplinePos.WorldLocation + RotatedSplineRotation.UpVector * AccSplineVerticalOffset.Value);
						Forward = TargetLocation - Player.ActorLocation;
					}
					else
					{
						AdditionalMoveDelta = (PrevSplineLocation - Player.ActorLocation).GetSafeNormal() * 350 * DeltaTime;
					}
				}

				if (RollAmount > 0)
					ForwardYaw *= -1;

				FRotator ToTargetRotation = FRotator::MakeFromXY(Forward, RotatedSplineRotation.RightVector);

				float RotationDuration = Player.IsMio() ? GapflyData.MioRotationDuration : GapflyData.ZoeRotationDuration;
				AccSplineRotation.AccelerateTo(ToTargetRotation, RotationDuration, DeltaTime);

				float MaxYaw = StrafeSettings.MaxTurningOffset.Yaw;
				float Yaw = Math::Clamp(ForwardYaw + MovementInput.Y * MaxYaw, -MaxYaw, MaxYaw);

				DragonComp.AnimParams.Banking = Math::Sign(Yaw);
				DragonComp.AnimParams.Pitching = 0;
				AccYaw.AccelerateTo(Yaw, TurningDuration, DeltaTime);

				FRotator AddRotation = Math::RotatorFromAxisAndAngle(AccSplineRotation.Value.UpVector, AccYaw.Value);
				FRotator MovementRotation = AccSplineRotation.Value + AddRotation;
				Movement.SetRotation(MovementRotation);

				float CurrentForwardSpeed = DragonComp.GetMovementSpeed();
				CurrentForwardSpeed = Math::Clamp(CurrentForwardSpeed, StrafeSettings.ForwardMinSpeed, StrafeSettings.ForwardMaxSpeed);

				CurrentForwardSpeed *= SplineFollowManagerComp.RubberBandingMoveSpeedMultiplier;
				FVector ForwardVelocity = MovementRotation.ForwardVector * CurrentForwardSpeed;

				FVector NewLocation = Player.ActorLocation + ForwardVelocity * DeltaTime;
				NewLocation = BoundarySpline.GetClampedLocationWithinBoundary(NewLocation);
				Movement.AddDelta(NewLocation - Player.ActorLocation);
				Movement.AddDelta(AdditionalMoveDelta);

				FTransform RotatedSplineTransform = SplineFollowManagerComp.CurrentSplineFollowData.Value.GetWorldTransform();
				RotatedSplineTransform.Rotation = RotatedSplineRotation.Quaternion();

				//Get rotation relative to rotatedsplinetransform, so that banking and pitching works correctly
				DragonComp.AnimParams.SplineRelativeDragonRotation = RotatedSplineTransform.InverseTransformRotation(Player.ActorRotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(AdultDragonLocomotionTags::AdultDragonFlying);
		}
	}
};