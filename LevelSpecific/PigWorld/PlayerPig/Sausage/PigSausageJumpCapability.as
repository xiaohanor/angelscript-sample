class UPigSausageJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40; // Tick before player jump

	default DebugCategory = PigTags::Pig;

	APigSausage PigSausage;
	UPlayerPigSausageComponent SausageComponent;

	UPlayerAirMotionComponent AirMotionComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	UHazeOffsetComponent MeshOffsetComponent;
	UPigSausageMovementSettings Settings;

	const float MaxTangentHeight = 150.0;

	EPigSausageMovementType MovementType;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SausageComponent = UPlayerPigSausageComponent::Get(Player);

		AirMotionComponent = UPlayerAirMotionComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSteppingMovementData();

		Settings = UPigSausageMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SausageComponent.IsSausageActive())
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (!MovementComponent.IsOnAnyGround())
			return false;

		if (!WasActionStarted(ActionNames::MovementJump))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SausageComponent.IsSausageActive())
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (MovementComponent.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Add impulse and set velocity
		FVector InitialHorizontalVelocity = MovementComponent.HorizontalVelocity.GetSafeNormal() * Math::Max(AirMotionComponent.Settings.HorizontalMoveSpeed * MovementComponent.MovementInput.Size(), MovementComponent.HorizontalVelocity.Size());
		FVector InitialVerticalVelocity = MovementComponent.WorldUp * UPigMovementSettings::GetSettings(Player).JumpImpulse;
		Player.SetActorHorizontalAndVerticalVelocity(InitialHorizontalVelocity, InitialVerticalVelocity);

		UPigSausageEventHandler::Trigger_JumpEvent(Player);
		Print("JUMP");

		PigSausage = SausageComponent.PigSausage;
		MeshOffsetComponent = SausageComponent.PigSausage.MeshOffsetComponent;

		MovementType = SausageComponent.GetCurrentMovement();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MeshOffsetComponent.ResetOffsetWithLerp(this, 0);
		// UPigSausageEventHandler::Trigger_LandEvent(Player);
		// Print("LAND");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				FVector AirControlVelocity = AirMotionComponent.CalculateStandardAirControlVelocity(MovementComponent.MovementInput, MovementComponent.HorizontalVelocity, DeltaTime);
				MoveData.AddHorizontalVelocity(AirControlVelocity);

				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();

				if(MovementType == EPigSausageMovementType::Floppy)
				{
					FQuat Rotation = GetTargetRotation();
					float InterpSpeed = MovementComponent.MovementInput.Size() + KINDA_SMALL_NUMBER;
					MoveData.InterpRotationTo(Rotation, 10 * InterpSpeed, false);
				}
				else
				{
					MoveData.InterpRotationToTargetFacingRotation(UPlayerJumpSettings::GetSettings(Player).FacingDirectionInterpSpeed * MovementComponent.MovementInput.Size());
				}

				MoveData.RequestFallingForThisFrame();
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			// Now do mesh rotation depending on velocity

			switch (MovementType)
			{
				case EPigSausageMovementType::FloppyForwardLateralRoll:
				{
					MeshOffsetComponent.LerpToTransform(this, Player.ActorTransform, 0.1, EInstigatePriority::High);
					break;
				}

				case EPigSausageMovementType::Floppy:
				{
					const float FloppyJumpFraction = 1.0 - Math::Saturate(ActiveDuration / 0.2);

					// Reset mesh offset over time
					PigSausage.SplineMesh.RelativeLocation = PigSausage.SplineMesh.RelativeLocation * FloppyJumpFraction;

					UpdateTangents(FloppyJumpFraction, DeltaTime);

					break;
				}

				case EPigSausageMovementType::Roll:
				{
					float RollAngle = MovementComponent.Velocity.Size() / (SausageComponent.PigSausage.Girth * 0.25 * 0.5);
					FQuat Roll = FQuat(Player.ActorRightVector, Math::DegreesToRadians(RollAngle)) * MeshOffsetComponent.ComponentQuat;

					// FQuat Yaw = FQuat::MakeFromX(Player.ActorRightVector);
					FQuat TargetYaw = FQuat::MakeFromX(Player.ActorRightVector);
					// FQuat Yaw = TargetYaw * FQuat::MakeFromX(MeshOffsetComponent.ForwardVector).Inverse() * FQuat::MakeFromX(Player.ActorForwardVector).Inverse() * Player.ActorQuat;


					FQuat MeshRotation = Roll;

					MeshOffsetComponent.LerpToTransform(this, FTransform(MeshRotation, Player.ActorLocation), 0.1, EInstigatePriority::High);
					break;
				}
			}
		}
	}

	FQuat GetTargetRotation() const
	{
		FVector FacingDirection = FVector::ZeroVector;
		if (MovementComponent.MovementInput.IsNearlyZero())
			FacingDirection = Player.ActorForwardVector;
		else
			FacingDirection = MovementComponent.MovementInput;

		// Flip forward if heading the other way
		if (FacingDirection.DotProduct(Player.ActorForwardVector) < 0)
			FacingDirection = -FacingDirection;

		return FQuat::MakeFromX(FacingDirection);
	}
	
	// Eman TODO: Constrain acceleration delta or substep
	void UpdateTangents(float FloppyFraction, float DeltaTime)
	{
		float TangentHeight = MaxTangentHeight * FloppyFraction;
		float Stiffness = Math::Max(1000 * FloppyFraction, 300);
		float Damping = SausageComponent.GetBouncyMeshDamping();

		// float MinDeltaTime = 0.01666;
		// float MaxDeltaTime = 0.03333;
		// float ConstrainedDeltaTime = Math::Clamp(DeltaTime, MinDeltaTime, MaxDeltaTime);

		FVector StartTangent = PigSausage.GetStartTangent() * FVector::ForwardVector + FVector::UpVector * TangentHeight;
		PigSausage.AcceleratedStartTangent.SpringTo(StartTangent, Stiffness, Damping, DeltaTime);

		FVector EndTangent = PigSausage.GetEndTangent() * FVector::ForwardVector - FVector::UpVector * TangentHeight;
		PigSausage.AcceleratedEndTangent.SpringTo(EndTangent, Stiffness, Damping, DeltaTime);

		PigSausage.UpdateTangents();
	}
}