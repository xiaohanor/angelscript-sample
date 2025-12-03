enum EAirDashDirection
{
	Forward,
	LeftStrafe,
	RightStrafe,
	Backward,
}

struct FAirDashDeactivationParams
{
	bool bInterrupted = true;
};

class UPlayerAirDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerMovementTags::AirDash);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Vault);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);

	default CapabilityTags.Add(n"AirDash");
	default BlockExclusionTags.Add(n"ExcludeAirJumpAndDash");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;
	default TickGroupSubPlacement = 5;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 5, 3);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerAirDashComponent AirDashComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerStepDashComponent StepDashComp;
	UPlayerSprintComponent SprintComp;
	UPlayerStrafeComponent StrafeComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerJumpComponent JumpComp;

	FVector Dir;

	FQuat StartingPlayerRotation;
	float32 InitialFrameDeltaTime;
	FQuat WantedPlayerRotation;
	bool bUseRotationDuration = false;
	bool bIsAutoTargeted = false;

	FVector StartPosition;
	FDashMovementCalculator DashMovementCalc;

	bool bUseCameraAmplification = false;
	const float CameraAmplificationMult = 0.3;
	float AppliedPivotOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AirDashComp = UPlayerAirDashComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		StepDashComp = UPlayerStepDashComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::GetOrCreate(Player);
		DevTogglesMovement::Dash::AutoAlwaysDash.MakeVisible();
	}

	bool WasActionDashStarted() const
	{
		if (WasActionStartedDuringTime(ActionNames::MovementDash, AirDashComp.Settings.InputBufferWindow))
			return true;
#if !RELEASE
		if (DevTogglesMovement::Dash::AutoAlwaysDash.IsEnabled(Player))
			return true;
#endif
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsOnWalkableGround())
			AirDashComp.bCanAirDash = true;

		// Manage the camera amplification
		if (IsActive() && bUseCameraAmplification)
		{
			AppliedPivotOffset = DashMovementCalc.GetDistanceAtTime(ActiveDuration) * CameraAmplificationMult;
			UCameraSettings::GetSettings(Player).PivotOffset.ApplyAsAdditive(FVector(
				AppliedPivotOffset, 0.0, 0.0
			), this, 0.0);
		}
		else if (AppliedPivotOffset > 0.0)
		{
			AppliedPivotOffset -= Math::Max(50.0, MoveComp.HorizontalVelocity.Size() * 0.6) * DeltaTime;
			if (AppliedPivotOffset <= 0.0)
			{
				UCameraSettings::GetSettings(Player).PivotOffset.Clear(this, 0.0);
			}
			else
			{
				UCameraSettings::GetSettings(Player).PivotOffset.ApplyAsAdditive(FVector(
					AppliedPivotOffset, 0.0, 0.0
				), this, 0.0);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MoveComp.IsOnWalkableGround())
			return false;

		if (!AirDashComp.bCanAirDash)
			return false;

		// Don't trigger the air dash if we did a ground jump just now, wait a bit until we are actually in the air
		if (JumpComp.StartedJumpingWithinDuration(JumpComp.Settings.PostJumpAirDashCooldown))
			return false;

		// If the air dash got cancelled while it was active (for example by landing), make sure we can't
		// jump and start a new air dash immediately
		if (DeactiveDuration < AirDashComp.Settings.DashDuration + 0.2)
			return false;

		//Input Buffer Window
		if (!WasActionDashStarted())
		{
			if(!Accessibility::AutoJumpDash::ShouldAutoAirDash(Player))
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FAirDashDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if (DashMovementCalc.IsFinishedAtTime(ActiveDuration))
		{
			Params.bInterrupted = false;
			return true;
		}

		if (MoveComp.HasAnyValidBlockingContacts())
			return true;

		if (MoveComp.HasImpulse())
			return true;

		if (MoveComp.IsOnWalkableGround())
		{
			Params.bInterrupted = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Dash, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);
		StartPosition = Player.ActorLocation;

		AirDashComp.bCanAirDash = false;
		AirDashComp.StartDash();

		float DashDistance = AirDashComp.Settings.DashDistance;

		Dir = MoveComp.MovementInput.GetSafeNormal();
		if (MoveComp.MovementInput.IsNearlyZero())
			Dir = Player.ActorForwardVector;

		// Check if there are any auto-targets to dash to instead
		float BestAutoTargetScore = 0.0;
		for (auto& AutoTarget : AirDashComp.AutoTargets)
		{
			float Score = 1.0;
			FVector TargetPoint = AutoTarget.Component.WorldTransform.TransformPosition(AutoTarget.LocalOffset);

			FVector FlatDelta = (TargetPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp);
			if (FlatDelta.IsNearlyZero())
				continue;

			if (AutoTarget.bCheckFlatDistance)
			{
				float Distance = FlatDelta.Size();
				if (Distance < AutoTarget.MinFlatDistance - KINDA_SMALL_NUMBER)
					continue;
				if (Distance > AutoTarget.MaxFlatDistance)
					continue;
				Score /= Math::Max(Distance, 0.001);
			}

			if (AutoTarget.bCheckHeightDifference)
			{
				float HeightDifference = (Player.ActorLocation - TargetPoint).DotProduct(MoveComp.WorldUp);
				if (HeightDifference < AutoTarget.MinHeightDifference)
					continue;
				if (HeightDifference > AutoTarget.MaxHeightDifference)
					continue;
				Score /= Math::Max(HeightDifference, 0.001);
			}

			if (AutoTarget.bCheckInputAngle)
			{
				float Angle = Dir.GetAngleDegreesTo(FlatDelta);
				if (Angle > AutoTarget.MaxInputAngle)
					continue;

				Score /= Math::Max(Angle, 0.001);
			}

			// Auto target passed all the checks, apply it
			if (Score > BestAutoTargetScore)
			{
				Dir = FlatDelta.GetSafeNormal();
				BestAutoTargetScore = Score;

				//Debug::DrawDebugLine(Player.ActorLocation, TargetPoint, FLinearColor::Red, 10.0, 10.0);

				// Calculate the shortening if we want to do it
				DashDistance = AirDashComp.Settings.DashDistance;
				if (AutoTarget.MaxShortening > 0.0)
				{
					float FlatDistance = FlatDelta.Size() - AutoTarget.ShortenExtraMargin;
					if (FlatDistance < DashDistance)
						DashDistance = Math::Max(DashDistance - AutoTarget.MaxShortening, FlatDistance);
				}
			}
		}

		// Apply a direction constraint if we have one
		if (!AirDashComp.DirectionConstraint.IsDefaultValue())
		{
			FAirDashDirectionConstraint Constraint = AirDashComp.DirectionConstraint.Get();
			Dir = Dir.ConstrainToCone(Constraint.Direction, Constraint.MaxAngleRadians);
		}

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			bUseCameraAmplification = false;
			if (StepDashComp.bTEMP_CameraAmplification)
			{
				// Apply Camera Impulse if we're going in the forward direction of the camera,
				// we don't do this otherwise, because it will feel weird
				float ForwardDot = Dir.DotProduct(Player.ViewRotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal());
				if (ForwardDot > 0.25)
				{
					bUseCameraAmplification = true;
				}
			}
		}

		FVector CameraDir = Player.ViewRotation.ForwardVector.ConstrainToPlane(Player.MovementWorldUp);
		StartingPlayerRotation = Player.ActorQuat;
		InitialFrameDeltaTime = GetCapabilityDeltaTime();

		if (Dir.GetAngleDegreesTo(-Player.ActorForwardVector) < AirDashComp.Settings.BackwardDashAngle)
		{
			// If we're turning around too much, we always do the backwards step
			AirDashComp.DashDirection = EAirDashDirection::Backward;
			
			if (StrafeComp.IsStrafeEnabled())
			{
				WantedPlayerRotation = CameraDir.ToOrientationQuat();
				bUseRotationDuration = false;
			}
			else
			{
				WantedPlayerRotation = Dir.ToOrientationQuat();
				bUseRotationDuration = true;
			}
		}
		else if (Dir.GetAngleDegreesTo(Player.ActorForwardVector) < AirDashComp.Settings.ForwardDashAngle
			|| Dir.GetAngleDegreesTo(CameraDir) < AirDashComp.Settings.ForwardDashAngle)
		{
			AirDashComp.DashDirection = EAirDashDirection::Forward;
			WantedPlayerRotation = Dir.ToOrientationQuat();
			bUseRotationDuration = false;
		}
		else
		{
			// When we do a strafe, we always want to end up with our forward pointing towards the camera (or backwards)
			if (StrafeComp.IsStrafeEnabled())
			{
				if (CameraDir.DotProduct(Player.ActorForwardVector) >= 0.0)
					WantedPlayerRotation = CameraDir.ToOrientationQuat();
				else
					WantedPlayerRotation = (-CameraDir).ToOrientationQuat();
				bUseRotationDuration = false;
			}
			else
			{
				WantedPlayerRotation = Dir.ToOrientationQuat();
				bUseRotationDuration = true;
			}

			if (Dir.DotProduct(Player.ActorRightVector) >= 0.0)
				AirDashComp.DashDirection = EAirDashDirection::RightStrafe;
			else
				AirDashComp.DashDirection = EAirDashDirection::LeftStrafe;
		}

		// If we have a velocity constraint, that goes on top of the dash velocity
		FVector StartVelocity = Player.GetActorHorizontalVelocity();
		if (!AirMotionComp.VelocityConstraint.IsDefaultValue())
		{
			float DashSpeed = DashDistance / AirDashComp.Settings.DashDuration;
			StartVelocity = StartVelocity.ProjectOnToNormal(Dir).GetClampedToMaxSize(DashSpeed);
		}

		DashMovementCalc = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			DashDistance = DashDistance,
			DashDuration = AirDashComp.Settings.DashDuration,
			DashAccelerationDuration = AirDashComp.Settings.DashAccelerationDuration,
			DashDecelerationDuration = AirDashComp.Settings.DashDecelerationDuration,
			InitialSpeed = StartVelocity.Size(),
			WantedExitSpeed = AirMotionComp.Settings.HorizontalMoveSpeed + AirDashComp.Settings.DashExitOverSpeed,
		);

		//Force Feedback
		if(AirDashComp.ForceFeedbackAirDash != nullptr)
			Player.PlayForceFeedback(AirDashComp.ForceFeedbackAirDash, false, false, this);

		Player.SetAnimTrigger(n"StartAirDash");
		Player.SetActorVerticalVelocity(FVector::ZeroVector);

		StepDashComp.BS_Strafe_Direction.Y = Player.ActorForwardVector.DotProduct(Dir);
		StepDashComp.BS_Strafe_Direction.X = Player.ActorRightVector.DotProduct(Dir);

		Accessibility::AutoJumpDash::StopAutoAirJumpDash(Player);

		UPlayerCoreMovementEffectHandler::Trigger_AirDash_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FAirDashDeactivationParams Params)
	{
		AirDashComp.StopDash();

		Player.ClearCameraSettingsByInstigator(this, 2.5);

		float MaxExitSpeed = DashMovementCalc.GetExitSpeed();
		if (!AirMotionComp.VelocityConstraint.IsDefaultValue())
			MaxExitSpeed += AirMotionComp.VelocityConstraint.Get().BaseVelocity.Size();

		Player.SetActorHorizontalVelocity(
			Player.ActorHorizontalVelocity.GetClampedToMaxSize(MaxExitSpeed)
		);
		
		UPlayerCoreMovementEffectHandler::Trigger_AirDash_Stopped(Player);

		Player.UnblockCapabilities(BlockedWhileIn::Dash, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.SetMovementFacingDirection(WantedPlayerRotation);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				//Define our direction based on input and allow it to snap within timeframe.
				if (ActiveDuration < AirDashComp.Settings.RedirectionWindow && !bIsAutoTargeted)
				{
					if (!MoveComp.MovementInput.IsNearlyZero())
					{
						Dir = MoveComp.MovementInput.GetSafeNormal();
						WantedPlayerRotation = Dir.ToOrientationQuat();
					}
				}

				float FrameMovement = 0.0;
				float FrameSpeed = 0.0;

				DashMovementCalc.CalculateMovement(
					ActiveDuration, DeltaTime,
					FrameMovement, FrameSpeed
				);

				Movement.AddDeltaWithCustomVelocity(
					Dir * FrameMovement,
					Dir * FrameSpeed,
					EMovementDeltaType::Horizontal
				);

				// If we have a velocity constraint, that goes on top of the dash velocity
				if (!AirMotionComp.VelocityConstraint.IsDefaultValue())
					Movement.AddHorizontalVelocity(AirMotionComp.VelocityConstraint.Get().BaseVelocity);

				if (bUseRotationDuration)
				{
					if (AirDashComp.Settings.SideStepRotationDuration > 0.0)
					{
						Movement.SetRotation(FQuat::Slerp(
							StartingPlayerRotation, WantedPlayerRotation,
							Math::Clamp((ActiveDuration + InitialFrameDeltaTime) / AirDashComp.Settings.SideStepRotationDuration, 0.0, 1.0)
						));
					}
					else
					{
						Movement.SetRotation(WantedPlayerRotation);
					}
				}
				else
				{
					Movement.InterpRotationTo(WantedPlayerRotation, AirDashComp.Settings.ForwardStepRotationInterpSpeed);
				}

				if (MoveComp.IsOnWalkableGround())
					Movement.OverrideStepDownAmountForThisFrame(54.0);

				// Apply gravity during the last bit of the air dash
				float GravityStartTimer = DashMovementCalc.GetTotalDashDuration() - AirDashComp.Settings.GravityDurationAtEnd;
				float GravityCurrentTime = ActiveDuration;
				if (GravityCurrentTime >= GravityStartTimer)
				{
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();
				}
				else if (GravityCurrentTime + DeltaTime >= GravityStartTimer)
				{
					// If we activated gravity 'during' this frame, scale the acceleration we get
					float GravityDuration = GravityCurrentTime + DeltaTime - GravityStartTimer;
					Movement.AddOwnerVerticalVelocity();
					Movement.AddDeltaWithCustomVelocity(
						MoveComp.GetGravity() * GravityDuration * GravityDuration * 0.5,
						MoveComp.GetGravity() * GravityDuration,
					);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
			
			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMove(Movement);

			if(MoveComp.NewStateIsOnWalkableGround())
				Player.Mesh.RequestLocomotion(n"Landing", this);
			else
			{
				// Player.Mesh.RequestLocomotion(n"AirDash", this);
				Player.Mesh.RequestLocomotion(Player.IsStrafeEnabled() ? n"StrafeAirDash" : n"AirDash", this);
			}
		}
	}
};
