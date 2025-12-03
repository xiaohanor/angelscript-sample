class UPigSausageMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default DebugCategory = PigTags::Pig;

	APigSausage PigSausage;

	UPlayerPigSausageComponent SausageComponent;
	UPlayerMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	UHazeOffsetComponent MeshOffsetComponent;
	UPigSausageMovementSettings Settings;

	UHazeCrumbSyncedFloatComponent CrumbedLateralSpeed;

	FHazeAcceleratedFloat AcceleratedFloppiness;
	FHazeAcceleratedVector AcceleratedRelativeMeshLocation;

	FHazeAcceleratedFloat AcceleratedInputSize;

	const float JiggleAmplitude = 30.0;
	const float JiggleSpeed = 18.0;
	const float MaxTangentHeight = 100.0;

	bool bFloped;

	// Input direction multiplier
	float LastSignedInput;

	bool bHasInputThisFrame;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SausageComponent = UPlayerPigSausageComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		MoveData = MovementComponent.SetupSteppingMovementData();

		Settings = UPigSausageMovementSettings::GetSettings(Player);

		CrumbedLateralSpeed = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"CrumbedSausageLateralSpeed");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SausageComponent.GetCurrentMovement() != EPigSausageMovementType::Floppy)
			return false;

		// Roll movement
		// if (IsActioning(ActionNames::PrimaryLevelAbility))
		// 	return false;

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
		if (SausageComponent.GetCurrentMovement() != EPigSausageMovementType::Floppy)
			return true;

		// Roll movement
		// if (IsActioning(ActionNames::PrimaryLevelAbility))
		// 	return true;

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

		AcceleratedFloppiness.SnapTo(0);
		AcceleratedRelativeMeshLocation.SnapTo(FVector::ZeroVector);

		// Wiggle some more if we just landed
		if (MovementComponent.WasInAir())
		{
			UPigSausageEventHandler::Trigger_LandEvent(Owner);
			float DeltaTime = Time::GetActorDeltaSeconds(Owner);
			PigSausage.AcceleratedStartTangent.SpringTo(PigSausage.GetStartTangent() * FVector::ForwardVector + FVector::UpVector * 200, 1000, 0, DeltaTime);
			PigSausage.AcceleratedEndTangent.SpringTo(PigSausage.GetStartTangent() * FVector::ForwardVector - FVector::UpVector * 200, 1000, 0, DeltaTime);
		}

		PigSausage.UpdateTangents();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MeshOffsetComponent.ResetOffsetWithLerp(this, 0.2);

		AcceleratedFloppiness.SnapTo(0);
		AcceleratedRelativeMeshLocation.SnapTo(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			bHasInputThisFrame = !MovementComponent.MovementInput.IsNearlyZero();

			const float SpeedFraction = Math::Abs(MovementComponent.HorizontalVelocity.Size() / Settings.ForwardSpeed);
			float Floppiness = Math::Lerp(SpeedFraction, MovementComponent.MovementInput.Size(), 0.5);
			AcceleratedFloppiness.AccelerateTo(Floppiness, 0.2, DeltaTime);

			if (HasControl())
			{
				// Handle velocity
				{
					// Accelerate from standstill
					if (MovementComponent.MovementInput.DotProduct(MovementComponent.Velocity) < -0.5)
						AcceleratedInputSize.SnapTo(0);
					else
						AcceleratedInputSize.AccelerateTo(MovementComponent.MovementInput.Size(), 0.2, DeltaTime);

					FVector Velocity = CalculateForwardFloppyVelocity(DeltaTime) * AcceleratedInputSize.Value;
					MoveData.AddHorizontalVelocity(Velocity);
				}

				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();

				MoveData.AddPendingImpulses();

				// Align forward with camera
				FQuat Rotation = GetTargetRotation();
				float InterpSpeed = MovementComponent.MovementInput.Size() + KINDA_SMALL_NUMBER;
				MoveData.InterpRotationTo(Rotation, 10 * InterpSpeed, false);

				// Force feedback juice
				float Intensity = MovementComponent.MovementInput.Size() * 0.05;
				const float JiggleSeed = ActiveDuration * JiggleSpeed;
				Player.SetFrameForceFeedback(Math::Pow(Math::Cos(JiggleSeed), 3) * 0.5, Math::Pow(Math::Sin(JiggleSeed), 3), 0, 0, Intensity);
				
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			// Juicy mesh movement
			const float JiggleSeed = ActiveDuration * JiggleSpeed;
			{
				Flop(JiggleSeed, DeltaTime);
				WiggleMesh(JiggleSeed, DeltaTime);
			}

			MovementComponent.ApplyMove(MoveData);
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

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked() && PigSausage != nullptr)
		{
			PigSausage.SplineMesh.SetRelativeLocation(
				Math::VInterpTo(
					PigSausage.SplineMesh.RelativeLocation,
					FVector::ZeroVector, DeltaTime, 10)
			);

			float TangentHeight = -30;
			const float Stiffness = 1000.0;
			const float Damping = SausageComponent.GetBouncyMeshDamping();

			FVector StartTangent = PigSausage.GetStartTangent() * FVector::ForwardVector + FVector::UpVector * TangentHeight;
			PigSausage.AcceleratedStartTangent.SpringTo(StartTangent, Stiffness, Damping, DeltaTime);

			FVector EndTangent = PigSausage.GetEndTangent() * FVector::ForwardVector - FVector::UpVector * TangentHeight;
			PigSausage.AcceleratedEndTangent.SpringTo(EndTangent, Stiffness, Damping, DeltaTime);

			PigSausage.UpdateTangents();
			SausageComponent.PigSausage.UpdateTangents();
		}
	}

	void Flop(float Seed, float DeltaTime, bool bReset = false)
	{
		// Rotate pitch to get flopiness
		{
			// float PitchAngle = Math::Pow(Math::Sin(Seed), 3) * JiggleAmplitude * Floppiness * 0.0;
			// FQuat Pitch = FQuat(MeshOffsetComponent.RightVector, Math::DegreesToRadians(PitchAngle));
			FQuat MeshRotation = /*Pitch */ Player.ActorQuat;

			if (!bReset)
				MeshOffsetComponent.LerpToRotation(this, MeshRotation, 0.1);
		}

		// Move mesh's height with floppiness to avoid clipping into floor
		{
			float Height = (Math::Sin(Seed) * JiggleAmplitude) + SausageComponent.GetHalfGirth();
			FVector RelativeMeshLocation = FVector::UpVector * (1.0 + Math::Abs(AcceleratedFloppiness.Value * 0.75)) + MovementComponent.WorldUp * Height * AcceleratedFloppiness.Value;
			if (bReset)
			{
				RelativeMeshLocation = FVector::ZeroVector;
			}

			float AccelerationDuration = bHasInputThisFrame ? 0.1 : 0.0;
			AcceleratedRelativeMeshLocation.AccelerateTo(RelativeMeshLocation, AccelerationDuration, DeltaTime);
			PigSausage.SplineMesh.SetRelativeLocation(AcceleratedRelativeMeshLocation.Value);

			if(RelativeMeshLocation.Z < 0 && bFloped == false)
			{
				UPigSausageEventHandler::Trigger_FlopEvent(Player);
				Print("Flop");
				bFloped = true;
			}
			else if(RelativeMeshLocation.Z > 1)
				bFloped = false;
		}
	}

	FVector CalculateForwardFloppyVelocity(float DeltaTime)
	{
		float SpeedFraction = Math::Saturate(MovementComponent.HorizontalVelocity.Size() / Settings.ForwardSpeed);
		float AccelerationMultiplier = Math::Lerp(0.5, 1.0, Math::Pow(SpeedFraction, 3));
		AccelerationMultiplier = Math::Saturate(Math::Pow(SpeedFraction + 0.5, 3));

		// Go full speed when input aligns with forward
		float Alignment = MovementComponent.MovementInput.DotProduct(Player.ActorForwardVector);

		FVector ForwardVelocity = Player.ActorForwardVector * Settings.ForwardSpeed * Alignment * AccelerationMultiplier;
		return ForwardVelocity;
	}

	// Eman TODO: Constrain acceleration delta or substep
	void WiggleMesh(float Seed, float DeltaTime, float Intensity = 1.0)
	{
		float TangentHeight = Math::Cos(Seed) * MaxTangentHeight * AcceleratedFloppiness.Value * Intensity;
		const float Stiffness = 1000.0;
		const float Damping = SausageComponent.GetBouncyMeshDamping();

		FVector StartTangent = PigSausage.GetStartTangent() * FVector::ForwardVector + FVector::UpVector * TangentHeight;
		PigSausage.AcceleratedStartTangent.SpringTo(StartTangent, Stiffness, Damping, DeltaTime);

		FVector EndTangent = PigSausage.GetEndTangent() * FVector::ForwardVector - FVector::UpVector * TangentHeight;
		PigSausage.AcceleratedEndTangent.SpringTo(EndTangent, Stiffness, Damping, DeltaTime);

		PigSausage.UpdateTangents();
	}
}