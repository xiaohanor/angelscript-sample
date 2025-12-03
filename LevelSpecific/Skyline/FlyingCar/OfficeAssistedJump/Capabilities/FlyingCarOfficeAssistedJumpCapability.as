struct FFlyingCarOfficeAssistedJumpCapabilityActivationParams
{
	FFlyingCarOfficeAssistedJump AssistedJump;
}

class UFlyingCarOfficeAssistedJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarMovement);

	// Tick before other movement stuff
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 70;

	default DebugCategory = n"FlyingCar";

	ASkylineFlyingCar CarOwner;

	UHazeMovementComponent MovementComponent;
	USkylineFlyingCarMovementData MoveData;

	USkylineFlyingCarGotySettings Settings;

	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	FFlyingCarOfficeAssistedJump AssistedJump;
	Trajectory::FOutCalculateVelocity AssistedTrajectory;

	FRotator PreviousMeshRotation = FRotator::ZeroRotator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarOwner = Cast<ASkylineFlyingCar>(Owner);
		MovementComponent = CarOwner.MovementComponent;
		MoveData = MovementComponent.SetupMovementData(USkylineFlyingCarMovementData);

		Settings = USkylineFlyingCarGotySettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FFlyingCarOfficeAssistedJumpCapabilityActivationParams& ActivationParams) const
	{
		if (!CarOwner.OfficeAssistedJumpComponent.IsAssistedJumpActive())
			return false;

		ActivationParams.AssistedJump = CarOwner.OfficeAssistedJumpComponent.GetCurrentAssistedJump();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (FlyingCar::IsOnSlidingGround(MovementComponent))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FFlyingCarOfficeAssistedJumpCapabilityActivationParams& ActivationParams)
	{
		PreviousMeshRotation = CarOwner.MeshRoot.WorldRotation;

		CarOwner.SetActiveHighway(nullptr);

		AssistedJump = ActivationParams.AssistedJump;
		AssistedTrajectory = Trajectory::CalculateParamsForPathWithHorizontalSpeed(CarOwner.ActorLocation, AssistedJump.WorldTarget.Location, Settings.GravityAmount * Settings.FreeFlyPitchGravityMultiplier.Min, CarOwner.ActorVelocity.Size());

		UMovementGravitySettings::SetGravityAmount(CarOwner, Settings.GravityAmount, this);
		UMovementGravitySettings::SetGravityScale(CarOwner, 1.0, this);

		CarOwner.OfficeAssistedJumpComponent.ClearJump();

		CarOwner.SetActorVelocity(AssistedTrajectory.Velocity);

		CarOwner.BlockCapabilities(FlyingCarTags::FlyingCarSplineUpdate, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AssistedJump = FFlyingCarOfficeAssistedJump();

		UMovementGravitySettings::ClearGravityAmount(CarOwner, this);
		UMovementGravitySettings::ClearGravityScale(CarOwner, this);

		CarOwner.UnblockCapabilities(FlyingCarTags::FlyingCarSplineUpdate, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				// Update the gravity amount
				float GravityAlpha = Math::Max(-0.2, -CarOwner.PitchInput) * 0.5;
				float GravityScale = Math::Lerp(Settings.FreeFlyPitchGravityMultiplier.Min, Settings.FreeFlyPitchGravityMultiplier.Max, (GravityAlpha)) * (ShouldApplyGravity(CarOwner.ActorVelocity) ? 1.0 : 0.0);
				UMovementGravitySettings::SetGravityScale(CarOwner, GravityScale, this);


				FVector Input = FVector(0.0, CarOwner.YawInput, CarOwner.PitchInput);
				FRotator DeltaRotation = FRotator::ZeroRotator;

				// Update Yaw steering
				{
					const float TargetOrientationChange = Input.Y * Settings.YawRotationSpeed;	
					DeltaRotation.Yaw += TargetOrientationChange * Settings.FreeFlySteeringMultiplier;
				}

				// Update Pitch steering
				{
					const float TargetOrientationChange = Input.Z * Settings.PitchRotationSpeed;	
					DeltaRotation.Pitch += TargetOrientationChange * Settings.FreeFlySteeringMultiplier;
				}

				FRotator WantedMovementRotation = CarOwner.ActorRotation;
				// Setup the wanted steering orientation from the input
				// and the max we can deviate from the spline direction
				{
					WantedMovementRotation.Yaw += (Math::Sign(Input.Y) * Settings.MaxFreeFlyOffsetSteeringAngle);
					WantedMovementRotation.Pitch += (Math::Sign(Input.Z) * Settings.MaxFreeFlyOffsetSteeringAngle);
					WantedMovementRotation.Roll += (Math::Sign(Input.Y) * Settings.MaxSplineOffsetSteeringAngle);
				}

				// Apply the delta rotation speed
				{
					FRotator ActorRotation = CarOwner.GetActorRotation();
					const float DeltaRotationYaw = Math::Abs(DeltaRotation.Yaw);
					if(DeltaRotationYaw > 0)
					{
						WantedMovementRotation.Yaw = CarOwner.RotateAxisTowardTargetWithDelta(ActorRotation.Yaw, WantedMovementRotation.Yaw, DeltaRotationYaw);
						WantedMovementRotation.Roll = CarOwner.RotateAxisTowardTargetWithDelta(CarOwner.MeshRoot.WorldRotation.Roll, WantedMovementRotation.Roll, DeltaRotationYaw * 3.0);
					}
					else
					{
						WantedMovementRotation.Yaw = ActorRotation.Yaw;
						WantedMovementRotation.Roll = Math::FInterpTo(CarOwner.MeshRoot.WorldRotation.Roll, WantedMovementRotation.Roll, DeltaTime, Settings.ReturnToIdleRotationSpeed * 3.0);
					}

					const float DeltaRotationPitch = Math::Abs(DeltaRotation.Pitch);
					if(DeltaRotationPitch > 0)
					{
						WantedMovementRotation.Pitch = CarOwner.RotateAxisTowardTargetWithDelta(ActorRotation.Pitch, WantedMovementRotation.Pitch, DeltaRotationPitch);
					}
					else
					{
						WantedMovementRotation.Pitch = ActorRotation.Pitch;
					}
				}
				WantedMovementRotation.Normalize();

				FRotator WantedMeshRoot = WantedMovementRotation;
				WantedMeshRoot += DeltaRotation * Settings.FakeMeshRotationAmount;
				WantedMeshRoot.Normalize();

				CarOwner.CrumbedMeshRotation.Value = Math::RInterpTo(PreviousMeshRotation, WantedMeshRoot, DeltaTime, 10.0);

				// Finalize the movement rotation from the final location
				FRotator CurrentMovementRotation = Math::RInterpTo(CarOwner.ActorRotation, WantedMovementRotation, DeltaTime, Settings.FreeFlyRotationInterpSpeed);

				const FVector CurrentVelocity = CarOwner.GetActorVelocity() + MovementComponent.GetPendingImpulse();
				FVector Horizontal = CurrentVelocity.VectorPlaneProject(CarOwner.MovementWorldUp);
				FVector Vertical = CurrentVelocity - Horizontal;

				// Update horizontal movement
				{
					FVector TargetHorizontalDir = FRotator(0.0, CurrentMovementRotation.Yaw, 0.0).ForwardVector;
					Horizontal = Math::VInterpTo(Horizontal.GetSafeNormal(), TargetHorizontalDir, DeltaTime, Settings.FreeFlyRotationInterpSpeed).GetSafeNormal() * Horizontal.Size();
				}

				FVector WantedMoveVelocity = Horizontal + Vertical;

				MoveData.AddVelocity(WantedMoveVelocity);
				MoveData.AddGravityAcceleration();

				MoveData.SetRotation(WantedMoveVelocity.ToOrientationQuat());
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}

		// Apply synced mesh rotation
		CarOwner.MeshRoot.WorldRotation = CarOwner.CrumbedMeshRotation.Value;
		PreviousMeshRotation = CarOwner.MeshRoot.WorldRotation;
	}

	bool ShouldApplyGravity(FVector CurrentVelocity) const
	{
		// Get constraint vector from max dive angle
		FVector Horizontal = CurrentVelocity.VectorPlaneProject(CarOwner.MovementWorldUp);
		FVector RightVector = CarOwner.MovementWorldUp.CrossProduct(Horizontal.GetSafeNormal()).GetSafeNormal();
		FVector InclinationConstraint = Horizontal.RotateAngleAxis(Settings.MaxFreeFlyDiveAngle, RightVector);
		FVector ConstraintUp = InclinationConstraint.GetSafeNormal().CrossProduct(RightVector).GetSafeNormal();

		// Don't apply gravity if ship exceeds max dive angle
		float Angle = ConstraintUp.GetAngleDegreesTo(CurrentVelocity.GetSafeNormal());
		return Angle < 90;
	}
}