class UPlayerPerchSplineDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerMovementTags::Perch);

	default CapabilityTags.Add(n"PerchSplineDash");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default TickGroupSubPlacement = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPerchComponent PerchComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	bool bCameraSettingsActive = false;

	FDashMovementCalculator DashMovementCalc;
	FSplinePosition SplinePos;
	float Cooldown;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		//Check camera setting status
		if (bCameraSettingsActive)
		{
			if (IsBlocked() || (!IsActive() && DeactiveDuration > PerchComp.Settings.DashCameraSettingsLingerTime))
			{
				Player.ClearCameraSettingsByInstigator(this, 2.5);
				bCameraSettingsActive = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!PerchComp.bIsGroundedOnPerchSpline)
			return false;
		
		if (PerchComp.bIsLandingOnSpline)
			return false;

		if (PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
			return false;

		//Input Buffer Window
		if (!WasActionStartedDuringTime(ActionNames::MovementDash, 0.08))
			return false;
		
		if (DeactiveDuration < PerchComp.Settings.DashCooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (PerchComp.Data.State != EPlayerPerchState::PerchingOnSpline)
			return true;

		if (DashMovementCalc.IsFinishedAtTime(ActiveDuration))
			return true;

		if (MoveComp.HasImpulse())
			return true;

		if (!PerchComp.bIsGroundedOnPerchSpline)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			//Apply Camera Settings
			Player.ApplyCameraSettings(PerchComp.PerchSplineDashCameraSetting, .5, this, SubPriority = 36);
			bCameraSettingsActive = true;
		}

		DashMovementCalc = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			DashDistance = PerchComp.Settings.DashDistance,
			DashDuration = PerchComp.Settings.DashDuration,
			DashAccelerationDuration = PerchComp.Settings.DashAccelerationDuration,
			DashDecelerationDuration = PerchComp.Settings.DashDecelerationDuration,
			InitialSpeed = Player.GetActorHorizontalVelocity().Size(),
			WantedExitSpeed = PerchComp.Settings.DashExitSpeed,
		);

		SplinePos = PerchComp.PerchSplinePosition;

		FVector Direction = MoveComp.MovementInput;
		if (Direction.Size() < 0.1)
			Direction = Player.ActorForwardVector;

		SplinePos.MatchFacingTo(FQuat::MakeFromX(Direction));

		// This capability maintains its own spline lock, so we don't want to use the spline lock resolver
		MoveComp.OverrideResolver(USteppingMovementResolver, this, EInstigatePriority::High);

		MoveComp.ApplyCustomMovementStatus(n"Perching", this);

		PerchComp.AnimData.bDashing = true;

		Player.PlayForceFeedback(PerchComp.PerchSplineDashFF, false, true, this);

		UPlayerCoreMovementEffectHandler::Trigger_Perch_Spline_DashStarted(Player);

		Player.BlockCapabilities(BlockedWhileIn::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ClearResolverOverride(USteppingMovementResolver, this);
		MoveComp.ClearCustomMovementStatus(this);

		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(BlockedWhileIn::Dash, this);

		// Don't allow inheriting the horizontal speed from a dash when we cancel it
		Player.SetActorHorizontalVelocity(
			Player.ActorHorizontalVelocity.GetClampedToMaxSize(DashMovementCalc.GetExitSpeed())
		);

		PerchComp.AnimData.bDashing = false;

		UPlayerCoreMovementEffectHandler::Trigger_Perch_Spline_DashStopped(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FSplinePosition PrevPosition = SplinePos;

				float FrameMovement;
				float FrameSpeed;

				DashMovementCalc.CalculateMovement(
					ActiveDuration, DeltaTime,
					FrameMovement, FrameSpeed
				);

				SplinePos.Move(FrameMovement);

				Movement.SetRotation(SplinePos.WorldRotation);
				Movement.AddDelta(SplinePos.WorldLocation - Player.ActorLocation);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);

			Player.Mesh.RequestLocomotion(n"Perch", this);

			FVector Direction = MoveComp.HorizontalVelocity.GetSafeNormal();
			Player.SetBlendSpaceValues(Direction.X, Direction.Y);

			if (IsValid(PerchComp.Data.ActiveSpline))
				PerchComp.Data.CurrentSplineDistance = PerchComp.Data.ActiveSpline.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		}
	}
};