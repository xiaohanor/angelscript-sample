class UPigSausageRollMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default DebugCategory = PigTags::Pig;

	APigSausage PigSausage;

	UPlayerPigSausageComponent SausageComponent;
	UPlayerMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	UHazeOffsetComponent MeshOffsetComponent;
	UPigSausageMovementSettings Settings;

	UHazeCrumbSyncedFloatComponent CrumbedLateralSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SausageComponent = UPlayerPigSausageComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
 		MoveData = MovementComponent.SetupSweepingMovementData();

		Settings = UPigSausageMovementSettings::GetSettings(Player);

		CrumbedLateralSpeed = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"SausageRollCrumbedLateralSpeed");
		CrumbedLateralSpeed.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility) && SausageComponent.GetCurrentMovement() != EPigSausageMovementType::Roll)
			return false;

		if (!SausageComponent.IsSausageActive())
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!MovementComponent.IsOnWalkableGround())
			return false;

		if (MovementComponent.HasUpwardsImpulse())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility) && SausageComponent.GetCurrentMovement() != EPigSausageMovementType::Roll)
			return true;

		if (!SausageComponent.IsSausageActive())
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (!MovementComponent.IsOnWalkableGround())
			return true;

		if (MovementComponent.HasUpwardsImpulse())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PigSausage = SausageComponent.PigSausage;
		MeshOffsetComponent = PigSausage.MeshOffsetComponent;
		UPigSausageEventHandler::Trigger_StartRollingEvent(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// FQuat MeshRotation = PigSausage.SplineMesh.ComponentQuat;
		MeshOffsetComponent.ResetOffsetWithLerp(this, 0.2);
		UPigSausageEventHandler::Trigger_StopRollingEvent(Player);
		// PigSausage.SplineMesh.SetWorldRotation(MeshRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Reset mesh offset over tim
		const float ResetFraction = 1.0 - Math::Saturate(ActiveDuration / 0.2);
		PigSausage.SplineMesh.RelativeLocation = PigSausage.SplineMesh.RelativeLocation * ResetFraction;

		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				// Handle lateral rofl movement
				FVector Velocity = CalculateVelocityConstrainedToDirection(Player.ActorForwardVector, DeltaTime);
				CrumbedLateralSpeed.SetValue(Velocity.Size() * Math::Sign(-Velocity.DotProduct(Player.ActorForwardVector)));
				MoveData.AddVelocity(Velocity);

				//Audio
				FPigWorldSausageRollParams Params;
				Params.RollSpeedAlpha = Velocity.Size()/500;
				UPigSausageEventHandler::Trigger_RollingEvent(Player,Params);

				// Don't rotate 360 degrees if player is doing 180
				FVector FacingDirection = MovementComponent.MovementInput.IsNearlyZero() ? Player.ActorForwardVector : MovementComponent.MovementInput;
				FQuat Rotation = FQuat::MakeFromX(FacingDirection);
				FVector SausageForward = Player.ActorRightVector;
				if (MovementComponent.WorldUp.CrossProduct(MovementComponent.MovementInput).GetSafeNormal().DotProduct(SausageForward) < 0)
					Rotation = FQuat(FVector::UpVector, Math::DegreesToRadians(180)) * Rotation;

				float InterpSpeed = MovementComponent.MovementInput.Size() + KINDA_SMALL_NUMBER;
				MoveData.InterpRotationTo(Rotation, 10 * InterpSpeed, false);

				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();

				MoveData.AddPendingImpulses();
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}

		// Tick mesh rotation (funky roll)
		FQuat MeshRotation = CalculateConsistentRollMeshRotation() * MeshOffsetComponent.ComponentQuat;
		FVector Offset = Player.ActorLocation + MovementComponent.WorldUp * (SausageComponent.GetHalfGirth() + Math::Abs(MeshRotation.Rotator().Pitch * 2.5));
		// float MeshOffsetDurationMultiplier = Math::Max(0.8, Math::Saturate(ActiveDuration / 0.2));
		FTransform MeshTransform = FTransform(MeshRotation, Offset);
		MeshOffsetComponent.LerpToTransform(this, MeshTransform, 0.1);

		TickTangents(DeltaTime);

		// FF juice
		float Intensity = Math::Square(Math::Saturate(MovementComponent.Velocity.Size() / Settings.LateralSpeed));
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::PerlinNoise1D(Math::Abs(Time::GameTimeSeconds * 5.46));
		FF.RightMotor = Math::PerlinNoise1D(Math::Abs(Time::GameTimeSeconds * 7.234));
		Player.SetFrameForceFeedback(FF, Intensity * 0.3);
	}

	void TickTangents(float DeltaTime)
	{
		// float Input = MovementComponent.MovementInput.Size();
		float Input = MovementComponent.Velocity.Size() / (Settings.LateralSpeed);
		float TangentHeight = 50 * Input;
		float Stiffness = 100;
		float Damping = 0.6;

		FVector StartTangent = PigSausage.GetStartTangent() * FVector::ForwardVector + FVector::UpVector * TangentHeight;
		PigSausage.AcceleratedStartTangent.SpringTo(StartTangent, Stiffness, Damping, DeltaTime);

		FVector EndTangent = PigSausage.GetEndTangent() * FVector::ForwardVector - FVector::UpVector * TangentHeight;
		PigSausage.AcceleratedEndTangent.SpringTo(EndTangent, Stiffness, Damping, DeltaTime);

		PigSausage.UpdateTangents();
	}

	float LastSignedInput;
	FVector CalculateVelocityConstrainedToDirection(FVector Direction, float DeltaTime)
	{
		float LateralInputFraction = MovementComponent.MovementInput.DotProduct(Direction);
		if (!Math::IsNearlyZero(LateralInputFraction))
			LastSignedInput = Math::Sign(LateralInputFraction);

		LateralInputFraction = Math::Abs(LateralInputFraction);

		// Get interp time (maybe accelerate?)
		float Acceleration = Math::Lerp(Settings.LateralDeceleration, Settings.LateralAcceleration, LateralInputFraction);

		// Interp speed taking direction into account
		const float TargetSpeed = Settings.LateralSpeed * LateralInputFraction * LastSignedInput;
		float Speed = (MovementComponent.Velocity.DotProduct(Direction));
		Speed = Math::FInterpTo(Speed, TargetSpeed, DeltaTime, Acceleration);

		return Direction * Speed;
	}

	FQuat CalculateLateralMeshRotation() const
	{
		float SpeedFraction = Math::Saturate(Math::Abs(CrumbedLateralSpeed.Value) / Settings.LateralSpeed);

		float RollAngle = CrumbedLateralSpeed.Value / (PigSausage.Girth * 0.25 * 0.5);
		FQuat Roll = FQuat(Player.ActorForwardVector, Math::DegreesToRadians(-RollAngle));

		float Wobble = MeshOffsetComponent.RelativeRotation.Pitch + Math::Sin(ActiveDuration * 20) * SpeedFraction * Settings.WobbleMultiplier;
		FQuat Pitch = FQuat(Player.ActorRightVector, Math::DegreesToRadians(Wobble));

		return Pitch * Roll;
	}

	FQuat CalculateConsistentRollMeshRotation()
	{
		float RollAngle = CrumbedLateralSpeed.Value / (PigSausage.Girth * 0.25 * 0.5);
		FQuat Roll = FQuat(Player.ActorRightVector, Math::DegreesToRadians(-RollAngle));

		// Remove inherited yaw rotation and just add what we want aND DESERVE GOD DAMMIT -USA! USA! USA!
		FQuat TargetYaw = FQuat::MakeFromX(Player.ActorRightVector);
		FQuat Yaw = TargetYaw * FQuat::MakeFromX(MeshOffsetComponent.ForwardVector).Inverse() * FQuat::MakeFromX(Player.ActorForwardVector).Inverse() * Player.ActorQuat;

		float SpeedFraction = Math::Saturate(Math::Abs(CrumbedLateralSpeed.Value) / Settings.LateralSpeed);
		float Wobble = MeshOffsetComponent.RelativeRotation.Pitch + Math::Sin(ActiveDuration * 20) * Math::Square(SpeedFraction) * Settings.WobbleMultiplier * 2.0;
		FQuat Pitch = FQuat(Player.ActorForwardVector, Math::DegreesToRadians(Wobble));

		return Roll * Yaw * Pitch;
	}
}