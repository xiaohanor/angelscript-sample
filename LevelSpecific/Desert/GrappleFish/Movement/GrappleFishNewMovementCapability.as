class UDesertGrappleFishNewMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	ADesertGrappleFish GrappleFish;
	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;
	UCameraUserComponent CameraUser;

	float CurrentRoll;
	float CurrentBlend;

	FHazeAcceleratedFloat AccLandscapeHeight;

	FVector MoveDir;

	bool bHadMountedPlayer = false;

	AHazePlayerCharacter MountedPlayer;

	float PoIForwardOffset = 1500.0;
	float PoISideOffset = 400.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleFish = Cast<ADesertGrappleFish>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USimpleMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
			return false;

		if (!GrappleFish.HasRider())
			return false;

		if (GrappleFish.HasAutoPilotOverride())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!Desert::HasLandscapeForLevel(GrappleFish.LandscapeLevel))
			return true;

		if (Desert::GetRelevantLandscapeLevel() != GrappleFish.LandscapeLevel)
			return true;

		if (!GrappleFish.HasRider())
			return true;

		if (GrappleFish.HasAutoPilotOverride())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MountedPlayer = GrappleFish.MountedPlayer;
		GrappleFish.State.Apply(EDesertGrappleFishState::Mounted, this, EInstigatePriority::High);
		GrappleFish.AccMoveSpeed.SnapTo(GrappleFishMovement::IdealMoveSpeed);
		UDesertGrappleFishEventHandler::Trigger_OnStartSwimming(GrappleFish);
		AccLandscapeHeight.SnapTo(Desert::GetLandscapeHeightByLevel(GrappleFish.ActorLocation, GrappleFish.LandscapeLevel));
		MoveDir = GrappleFish.ActorForwardVector;
		CurrentRoll = GrappleFish.SharkMesh.RelativeRotation.Roll;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// UDesertGrappleFishEventHandler::Trigger_OnStopSwimming(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
		{
			return;
		}
		if (HasControl())
		{
			float MoveSpeed = GrappleFish.GetMovementSpeed();
			GrappleFish.AccMoveSpeed.AccelerateTo(MoveSpeed, GrappleFishMovement::MovementAccelerationDuration, DeltaTime);

			float HorizontalInput = GrappleFish.PlayerHorizontalInput;
			FVector DesiredMoveDelta;

			float RollSpeed = GrappleFishVisuals::RollInterpSpeed;
			float RollTarget = 0;
			float TurningDirection = 0;

			float TurnBlendSpeed = GrappleFishVisuals::TurnBlendInterpSpeed;

			if (Math::IsNearlyZero(HorizontalInput))
			{
				GrappleFish.AccTurnSpeed.AccelerateToWithStop(0, GrappleFishMovement::TurnDecelerationDuration, DeltaTime, 0.01 * GrappleFishMovement::MaxTurnSpeedDeg);
				TurnBlendSpeed = GrappleFishVisuals::NoInputTurnBlendInterpSpeed;
				RollSpeed = GrappleFishVisuals::NoInputRollnterpSpeed;
			}
			else
			{
				float TurnDuration = GrappleFishMovement::TurnAccelerationDuration;
				if ((GrappleFish.AccTurnSpeed.Value < 0 && HorizontalInput > 0) || (GrappleFish.AccTurnSpeed.Value > 0 && HorizontalInput < 0))
				{
					TurnDuration += GrappleFishMovement::TurnChangeDirectionAdditionalDuration;
				}
				GrappleFish.AccTurnSpeed.AccelerateTo(GrappleFishMovement::MaxTurnSpeedDeg * HorizontalInput, TurnDuration, DeltaTime);
			}

			FVector Forward = GrappleFish.ActorForwardVector.RotateAngleAxis(GrappleFish.AccTurnSpeed.Value * DeltaTime, FVector::UpVector);
			DesiredMoveDelta = Forward * GrappleFish.AccMoveSpeed.Value * DeltaTime;
			TurningDirection = GrappleFish.AccTurnSpeed.Value / GrappleFishMovement::MaxTurnSpeedDeg;
			if (Math::IsNearlyZero(GrappleFish.AccTurnSpeed.Value))
				RollTarget = 0;
			else
				RollTarget = GrappleFishVisuals::MaxRollAmount * TurningDirection;

			CurrentBlend = Math::FInterpTo(CurrentBlend, TurningDirection * GrappleFishVisuals::MaxBlendFrac, DeltaTime, TurnBlendSpeed);
			GrappleFish.AnimData.TurnBlend = CurrentBlend;

			CurrentRoll = Math::FInterpTo(CurrentRoll, RollTarget, DeltaTime, RollSpeed);

			GrappleFish.Velocity = DesiredMoveDelta / DeltaTime;

			FVector TargetLocation = GrappleFish.ActorLocation + DesiredMoveDelta;

			float LandscapeHeight = Desert::GetLandscapeHeightByLevel(TargetLocation, GrappleFish.LandscapeLevel);
			AccLandscapeHeight.AccelerateTo(LandscapeHeight, GrappleFishMovement::LandscapeHeightAccelerationDuration, DeltaTime);

			TargetLocation.Z = AccLandscapeHeight.Value;
			FVector FinalMoveDelta = TargetLocation - GrappleFish.ActorLocation;

			Movement.AddDelta(FinalMoveDelta);

			FVector Normal = Desert::GetLandscapeNormal(GrappleFish.ActorTransform, GrappleFish.LandscapeLevel);
			GrappleFish.AccLandscapeNormal.AccelerateTo(Normal, GrappleFishMovement::LandscapeHeightAccelerationDuration, DeltaTime);

			FRotator MovementRot = FRotator::MakeFromXZ(FinalMoveDelta.GetSafeNormal().VectorPlaneProject(FVector::UpVector), FVector::UpVector);
			Movement.SetRotation(MovementRot);

			FVector RotationForward = FinalMoveDelta.GetSafeNormal();
			GrappleFish.AccMeshForward.AccelerateTo(RotationForward, 0.5, DeltaTime);

			if (GrappleFish.MountedPlayer != nullptr)
			{
				bool bPlayerInputing = !Math::IsNearlyZero(HorizontalInput);
				bool bTurningRight = TurningDirection > KINDA_SMALL_NUMBER;
				bool bTurningLeft = TurningDirection < -KINDA_SMALL_NUMBER;
				float LeftFF = 0;
				float RightFF = 0;
				if (bTurningLeft)
				{
					LeftFF = Math::Sin(Time::GameTimeSeconds * 100) * 0.2;
					RightFF = Math::Sin(Time::GameTimeSeconds * 100) * 0.00625;
				}
				else if (bTurningRight)
				{
					RightFF = Math::Sin(Time::GameTimeSeconds * 100) * 1;
					LeftFF = Math::Sin(Time::GameTimeSeconds * 100) * 0.00625;
				}
				else
				{
					LeftFF = Math::Sin(Time::GameTimeSeconds * 20) * 0.05;
					RightFF = Math::Sin(Time::GameTimeSeconds * 20) * 0.05;
				}
				GrappleFish.MountedPlayer.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
			}
			GrappleFish.SyncedMeshRotation.SetValue(FRotator(0, 0, CurrentRoll));
			GrappleFish.SyncedRootRotation.SetValue(FRotator::MakeFromXZ(GrappleFish.AccMeshForward.Value, GrappleFish.AccLandscapeNormal.Value));
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);

		GrappleFish.SharkMesh.RelativeRotation = GrappleFish.SyncedMeshRotation.GetValue();
		GrappleFish.SharkRoot.SetWorldRotation(GrappleFish.SyncedRootRotation.GetValue());
		GrappleFish.AutoPilotSplinePosition = GrappleFish.AutoPilotSpline.Spline.GetClosestSplinePositionToWorldLocation(GrappleFish.ActorLocation);
	}
};