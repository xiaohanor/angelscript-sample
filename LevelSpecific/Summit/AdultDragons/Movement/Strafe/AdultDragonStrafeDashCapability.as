class UAdultDragonStrafeDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAirDash);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 110;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAdultDragonComponent DragonComp;
	UAdultDragonStrafeComponent StrafeComp;
	UAdultDragonSplineFollowManagerComponent SplineFollowManagerComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UAdultDragonStrafeSettings StrafeSettings;
	AAdultDragonBoundarySpline BoundarySpline;

	FHazeAcceleratedQuat AccRotation;

	FRotator DashRotationOffset;
	FRotator DashRotation;

	float StartForwardSpeed = 0.0;

	bool bFirstFrameActive = false;

	FHazeAcceleratedFloat AccBoundaryForceMagnitude;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		StrafeComp = UAdultDragonStrafeComponent::Get(Player);
		SplineFollowManagerComp = UAdultDragonSplineFollowManagerComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);
		BoundarySpline = TListedActors<AAdultDragonBoundarySpline>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		if (DragonComp.bGapFlying)
			return false;

		if (!WasActionStarted(ActionNames::MovementDash))
			return false;

		float _;
		if (BoundarySpline.GetIsOutsideBoundary(Player.ActorLocation, _))
			return false;

		if (DeactiveDuration < StrafeSettings.DashCooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration > StrafeSettings.DashDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(AdultDragonCapabilityTags::AdultDragonSmashMode, this);

		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Dash, this, EInstigatePriority::High);
		StrafeComp.AnimationState.Apply(EAdultDragonStormStrafeState::Dash, this, EInstigatePriority::High);
		Player.PlayCameraShake(StrafeComp.DashCameraShake, this, 0.75);
		Player.ApplyCameraSettings(StrafeComp.DashCameraSettings, 0.15, this, EHazeCameraPriority::High);
		Player.PlayForceFeedback(DragonComp.DashRumble, false, false, this);

		FVector MovementInput = MoveComp.MovementInput;
		TOptional<FAdultDragonSplineFollowData> CurrentFollowSplineData = SplineFollowManagerComp.CurrentSplineFollowData;
		if (CurrentFollowSplineData.IsSet())
		{
			DashRotationOffset = GetDashRotationOffset(MovementInput);
		}

		// DragonComp.bCanInputRotate = false;
		DragonComp.bIsDashing = true;
		DragonComp.AnimParams.bDashInitialized = true;
		bFirstFrameActive = true;

		AccRotation.SnapTo(Player.ActorRotation.Quaternion());

		StartForwardSpeed = Player.ActorVelocity.DotProduct(Player.ActorForwardVector);

		float DistanceOutside = 0;
		if (BoundarySpline.GetIsOutsideBoundary(Player.ActorLocation, DistanceOutside))
		{
			float ForceMagnitude = Math::Min(DistanceOutside * 4, 13000);
			AccBoundaryForceMagnitude.SnapTo(ForceMagnitude);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bIsDashing = false;
		// DragonComp.bCanInputRotate = true;
		Player.UnblockCapabilities(AdultDragonCapabilityTags::AdultDragonSmashMode, this);

		DragonComp.AnimationState.Clear(this);
		StrafeComp.AnimationState.Clear(this);
		Player.ClearCameraSettingsByInstigator(this, 3.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bFirstFrameActive && DragonComp.AnimParams.bDashInitialized)
			DragonComp.AnimParams.bDashInitialized = false;

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;

				TOptional<FAdultDragonSplineFollowData> CurrentFollowSplineData = SplineFollowManagerComp.CurrentSplineFollowData;
				if (CurrentFollowSplineData.IsSet())
				{
					if (StrafeSettings.bRedirectDuringDash)
					{
						FRotator TargetDashRotationOffset = GetDashRotationOffset(MovementInput);
						DashRotationOffset = Math::RInterpConstantTo(DashRotationOffset, TargetDashRotationOffset, DeltaTime, StrafeSettings.DashRedirectSpeed);
					}

					DashRotation = GetDashRotation(DashRotationOffset, CurrentFollowSplineData.Value);
					StrafeComp.InputRotation = DashRotationOffset;

					// FRotator InputRotation = FRotator(MovementInput.X * StrafeSettings.MaxTurningOffset.Pitch, MovementInput.Y * StrafeSettings.MaxTurningOffset.Yaw, 0);
					// StrafeComp.InputRotation = InputRotation;

					FSplinePosition SplinePosition = SplineFollowManagerComp.CurrentSplineFollowData.Value.GetMostActiveSplinePosition();
					//StrafeComp.InputRotation = SplinePosition.WorldTransform.TransformRotation(DashRotationOffset);
					float TurningDuration = 6;
					StrafeComp.AccMovementRotation.AccelerateTo(DashRotation.Quaternion(), TurningDuration, DeltaTime);

					// Movement.SetRotation(StrafeComp.AccMovementRotation.Value);
					FVector Forward = StrafeComp.AccMovementRotation.Value.ForwardVector;
					float CurrentForwardSpeed = DragonComp.GetMovementSpeed();

					CurrentForwardSpeed = Math::Clamp(CurrentForwardSpeed, StrafeSettings.ForwardMinSpeed, StrafeSettings.ForwardMaxSpeed);

					CurrentForwardSpeed *= SplineFollowManagerComp.RubberBandingMoveSpeedMultiplier;
					FVector ForwardVelocity = Forward * CurrentForwardSpeed;

					float DashAlpha = ActiveDuration / StrafeSettings.DashDuration;

					float DashSpeedAlpha = StrafeSettings.DashSpeedCurve.GetFloatValue(DashAlpha);

					FVector DashVelocity = Forward.VectorPlaneProject(SplinePosition.WorldForwardVector) * DashSpeedAlpha * StrafeSettings.DashMaxSpeed;
					// FVector TargetLocation = Player.ActorLocation + Delta;
					FVector BoundaryForce;
					float DistanceOutside = 0;
					if (BoundarySpline.GetIsOutsideBoundary(Player.ActorLocation, DistanceOutside))
					{
						float ForceMagnitude = Math::Min(DistanceOutside * 4, 10000);
						AccBoundaryForceMagnitude.AccelerateTo(ForceMagnitude, 1.0, DeltaTime);
						auto SplinePos = SplineFollowManagerComp.CurrentSplineFollowData.Value.GetMostActiveSplinePosition();
						BoundaryForce = (SplinePos.WorldLocation - Player.ActorLocation).GetSafeNormal() * AccBoundaryForceMagnitude.Value;
						ForwardVelocity = ForwardVelocity.RotateTowards(SplinePos.WorldForwardVector, 15 * DeltaTime);
						DashVelocity = DashVelocity.VectorPlaneProject(ForwardVelocity.GetSafeNormal());
					}
					else
					{
						AccBoundaryForceMagnitude.AccelerateTo(0, 1.0, DeltaTime);
					}
					Print(f"{DistanceOutside=}", 0);
					FVector TargetLocation = Player.ActorLocation + (ForwardVelocity + BoundaryForce + DashVelocity) * DeltaTime;
					FVector Delta = TargetLocation - Player.ActorLocation;
					Movement.AddDelta(Delta);
					Movement.SetRotation(FRotator::MakeFromXZ(ForwardVelocity.GetSafeNormal(), SplinePosition.WorldUpVector));

					DragonComp.AnimParams.SplineRelativeDragonRotation = SplineFollowManagerComp.CurrentSplineFollowData.Value.GetWorldTransform().InverseTransformRotation(Player.ActorRotation);

					TEMPORAL_LOG(StrafeComp)
						.DirectionalArrow("Actor Forward", Player.ActorLocation, Player.ActorForwardVector * 5000, 10, 40, FLinearColor::Red)
						.DirectionalArrow("Actor Up", Player.ActorLocation, Player.ActorUpVector * 5000, 10, 40, FLinearColor::Blue)
						.DirectionalArrow("Actor Right", Player.ActorLocation, Player.ActorRightVector * 5000, 10, 40, FLinearColor::Green)
						.DirectionalArrow("Dash Velocity", Player.ActorLocation, DashVelocity, 10, 40, FLinearColor::Teal)
						.DirectionalArrow("Dash Rotation", Player.ActorLocation, DashRotation.ForwardVector * 5000, 10, 40, FLinearColor::Red);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(AdultDragonLocomotionTags::AdultDragonFlying);
		}
		bFirstFrameActive = false;
	}

	FRotator GetDashRotationOffset(FVector MovementInput) const
	{
		FRotator InputRotation = FRotator(MovementInput.X * StrafeSettings.DashMaxTurningOffset.Pitch, MovementInput.Y * StrafeSettings.DashMaxTurningOffset.Yaw, 0);
		return InputRotation;
	}

	FRotator GetDashRotation(FRotator In_DashRotationOffset, FAdultDragonSplineFollowData In_CurrentSplineFollowData) const
	{
		return In_CurrentSplineFollowData.GetWorldTransform().TransformRotation(In_DashRotationOffset);
	}
}