class USkylineFlyingCarGotyFreeMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarMovement);
	default CapabilityTags.Add(FlyingCarTags::FlyingCarDash);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASkylineFlyingCar Car;
	UHazeMovementComponent MoveComp;
	USkylineFlyingCarGotySettings Settings;
	USkylineFlyingCarMovementData Movement;

	FVector ActivationDirection;
	FRotator PreviousMeshRotation = FRotator::ZeroRotator;

	FHazeAcceleratedVector AccInput;

	float RollMultiplier;

	// Holds interpolated car actor rotation, used for visuals (mesh rotation)
	FRotator InterpedActorRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Car = Cast<ASkylineFlyingCar>(Owner);
		Settings = USkylineFlyingCarGotySettings::GetSettings(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USkylineFlyingCarMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (Car.ActiveHighway != nullptr)
			return false;

		FSkylineFlyingCarSplineParams SplineData;
		if(!Car.GetSplineDataAtPosition(Car.GetActorLocation(), SplineData))
			return true;

		if (SplineData.bHasReachedEndOfSpline)
			return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (Car.ActiveHighway != nullptr)
			return true;

		// FSkylineFlyingCarSplineParams SplineData;
		// if(!Car.GetSplineDataAtPosition(Car.GetActorLocation(), SplineData))
		// 	return false;

		// if(SplineData.bHasReachedEndOfSpline)
		// 	return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ActivationDirection = Car.ActorForwardVector;
		PreviousMeshRotation = Car.MeshRoot.WorldRotation;
		InterpedActorRotation = Car.ActorRotation;

		// This is stupid, this is why car stupidly slows down when exiting tunnel and colliding with car. FEEX!
		FVector InitialVelocity = CalculateInitialVelocity();
		Car.SetActorVelocity(InitialVelocity);

		Car.bIsFreeFyling = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Car.bIsFreeFyling = false;
		UMovementGravitySettings::ClearGravityAmount(Car, this);
		UMovementGravitySettings::ClearGravityScale(Car, this);
		//UMovementSweepingSettings::ClearGroundedTraceDistance(Car, this);
	}

	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaTime)
	{
		UMovementGravitySettings::SetGravityAmount(Car, Settings.GravityAmount, this, EHazeSettingsPriority::Defaults);

		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				const bool bIsGrounded = MoveComp.IsOnAnyGround();

				FSkylineFlyingCarSplineParams SplineParams;
				Car.GetSplineDataAtPosition(Car.GetActorLocation(), SplineParams);
				const FSplinePosition& CurrentSplinePosition = SplineParams.SplinePosition;
				FSplinePosition SplinePosition = CurrentSplinePosition;

				// Update the gravity amount
				float GravityAlpha = 1.0 - ((Car.PitchInput + 1.0) * 0.5);
				float GravityScale = Math::Lerp(Settings.FreeFlyPitchGravityMultiplier.Min, Settings.FreeFlyPitchGravityMultiplier.Max, Math::Square(GravityAlpha)) * (ShouldApplyGravity(Car.ActorVelocity) ? 1.0 : 0.0);
				UMovementGravitySettings::SetGravityScale(Car, GravityScale, this);

				FVector Input = FVector(0.0, Car.YawInput, Car.PitchInput);

				AccInput.AccelerateTo(Input, 0.5, DeltaTime);

				Input = AccInput.Value;
				
				FRotator DeltaRotation = FRotator::ZeroRotator;

				// Update Yaw steering
				{
					const float TargetOrientationChange = Input.Y * Settings.YawRotationSpeed;	
					DeltaRotation.Yaw += TargetOrientationChange * Settings.FreeFlySteeringMultiplier;
				}

				// Update Pitch steering
				if(!bIsGrounded)
				{
					const float TargetOrientationChange = Input.Z * Settings.PitchRotationSpeed;	
					DeltaRotation.Pitch += TargetOrientationChange * Settings.FreeFlySteeringMultiplier;
				}

				// Apply the look ahead distance
				SplinePosition.Move(Math::Max(Settings.SplineGuidanceDistance, 1.0));
				FRotator WantedMovementRotation = ActivationDirection.ToOrientationRotator();
				WantedMovementRotation = Car.ActorRotation;
		
				// Setup the wanted steering orientation from the input
				// and the max we can deviate from the spline direction
				{
					WantedMovementRotation.Yaw += (Math::Sign(Input.Y) * Settings.MaxFreeFlyOffsetSteeringAngle);
					WantedMovementRotation.Pitch += (Math::Sign(Input.Z) * Settings.MaxFreeFlyOffsetSteeringAngle);
					WantedMovementRotation.Roll += (Math::Sign(Input.Y) * Settings.MaxSplineOffsetSteeringAngle);
				}

				// Apply the delta rotation speed
				{
					FRotator ActorRotation = Car.GetActorRotation();
					const float DeltaRotationYaw = Math::Abs(DeltaRotation.Yaw);
					if(DeltaRotationYaw > 0)
					{
						WantedMovementRotation.Yaw = Car.RotateAxisTowardTargetWithDelta(ActorRotation.Yaw, WantedMovementRotation.Yaw, DeltaRotationYaw);
						WantedMovementRotation.Roll = Car.RotateAxisTowardTargetWithDelta(Car.MeshRoot.WorldRotation.Roll, WantedMovementRotation.Roll, DeltaRotationYaw * 3.0);
					}
					else
					{
						WantedMovementRotation.Yaw = ActorRotation.Yaw;
						WantedMovementRotation.Roll = Math::FInterpTo(Car.MeshRoot.WorldRotation.Roll, WantedMovementRotation.Roll, DeltaTime, Settings.ReturnToIdleRotationSpeed * 3.0);
					}

					const float DeltaRotationPitch = Math::Abs(DeltaRotation.Pitch);
					if(DeltaRotationPitch > 0)
					{
						WantedMovementRotation.Pitch = Car.RotateAxisTowardTargetWithDelta(ActorRotation.Pitch, WantedMovementRotation.Pitch, DeltaRotationPitch);
					}
					else
					{
						WantedMovementRotation.Pitch = ActorRotation.Pitch;
					}
				}
				WantedMovementRotation.Normalize();

				// Set the mesh rotation and the fake mesh rotation
				{
					// Interpolate movement rotation
					InterpedActorRotation = Math::RInterpTo(InterpedActorRotation, Car.ActorRotation, DeltaTime, 15);

					// Calculate local mesh rotation
					FRotator MeshRotation = FRotator(Settings.PitchMeshRotation.UpdateAngle(Car.PitchInput, DeltaTime),
										Settings.YawMeshRotation.UpdateAngle(Car.YawInput, DeltaTime),
										Settings.RollMeshRotation.UpdateAngle(Car.YawInput, DeltaTime));

					// Combine!
					Car.CrumbedMeshRotation.Value = InterpedActorRotation + MeshRotation;
				}

				// Finalize the movement rotation from the final location
				FRotator CurrentMovementRotation = Math::RInterpTo(Car.ActorRotation, WantedMovementRotation, DeltaTime, Settings.FreeFlyRotationInterpSpeed);

				const FVector CurrentVelocity = Car.GetActorVelocity() + MoveComp.GetPendingImpulse();
				FVector Horizontal = CurrentVelocity.VectorPlaneProject(Car.MovementWorldUp);
				FVector Vertical = CurrentVelocity - Horizontal;

				if(bIsGrounded)
				{
					WantedMovementRotation.Pitch = 0.0;
					CurrentMovementRotation.Pitch = 0.0;
					Vertical = FVector::ZeroVector;
					//UMovementSweepingSettings::SetGroundedTraceDistance(Car, FMovementSettingsValue::MakeValue(100.0), this);
				}
				// else
				// {
				// 	UMovementSweepingSettings::ClearGroundedTraceDistance(Car, this);
				// }

				// Update horizontal movement
				{
					FVector TargetHorizontalDir = FRotator(0.0, CurrentMovementRotation.Yaw, 0.0).ForwardVector;
					Horizontal = Math::VInterpTo(Horizontal.GetSafeNormal(), TargetHorizontalDir, DeltaTime, Settings.FreeFlyRotationInterpSpeed).GetSafeNormal() * Horizontal.Size();

					if(bIsGrounded)
					{
						float GroundMoveSpeed = Math::FInterpTo(Horizontal.Size(), Settings.HouseMoveSpeed, DeltaTime, 1.0);
						GroundMoveSpeed = Math::FInterpConstantTo(GroundMoveSpeed, Settings.HouseMoveSpeed, DeltaTime, 10.0);
						Horizontal = Horizontal.GetSafeNormal() * GroundMoveSpeed;
					}
				}

				FVector WantedMoveVelocity = Horizontal + Vertical;

				Movement.AddVelocity(WantedMoveVelocity);
				Movement.AddGravityAcceleration();

				Movement.SetRotation(WantedMoveVelocity.ToOrientationQuat());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}

		if (!Car.IsSplineDashing())
			Car.MeshRoot.WorldRotation = (Car.MeshRootRotationOffset * Car.CrumbedMeshRotation.Value.Quaternion()).Rotator();

		PreviousMeshRotation = Car.MeshRoot.WorldRotation;
	}

	bool ShouldApplyGravity(FVector CurrentVelocity) const
	{
		// Get constraint vector from max dive angle
		FVector Horizontal = CurrentVelocity.VectorPlaneProject(Car.MovementWorldUp);
		FVector RightVector = Car.MovementWorldUp.CrossProduct(Horizontal.GetSafeNormal()).GetSafeNormal();
		FVector InclinationConstraint = Horizontal.RotateAngleAxis(Settings.MaxFreeFlyDiveAngle, RightVector);
		FVector ConstraintUp = InclinationConstraint.GetSafeNormal().CrossProduct(RightVector).GetSafeNormal();

		// Don't apply gravity if ship exceeds max dive angle
		float Angle = ConstraintUp.GetAngleDegreesTo(CurrentVelocity.GetSafeNormal());
		return Angle < 90;
	}

	// Eman TODO: Temp pre-UXR (Sep 2022) hack to avoid conflicting with previous shitty behaviour
	FVector CalculateInitialVelocity() const
	{
		// Test if we come from ground movement
		if (Car.Pilot != nullptr)
		{
			USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(Car.Pilot);
			if (PilotComponent != nullptr)
			{
				if (PilotComponent.GetAndConsumeWasGroundMoving())
					return Car.ActorVelocity;
			}
		}

		// Shitty hardcode, will fix after uxr
		FVector InitialVelocity = Car.ActorVelocity * 1.5;

		// Hax for when we start with no velocity (i.e. when starting a level with no spline reference)
		if (InitialVelocity.IsNearlyZero())
			InitialVelocity = Car.ActorForwardVector * Settings.SplineMoveSpeed;

		return InitialVelocity;
	}

	void SteerTowardsClosestSpline()
	{
		// Turn towards the closest spline if we can
		// if(SplineParams.HighWay != nullptr && Settings.SplineGrabDistance > 0 && !SplineParams.bHasReachedEndOfSpline)
		// {
		// 	float Distance = Car.ActorLocation.Distance(SplineParams.SplinePosition.WorldLocation);
		// 	Distance = Math::Max(Distance - SplineParams.HighWay.TunnelRadius, 0.0);
		// 	float SplineGrabAlpha = 1.0 - Math::Min(Distance / Settings.SplineGrabDistance, 1.0);
		// 	if(SplineGrabAlpha > KINDA_SMALL_NUMBER)
		// 	{
		// 		const float RawSplineDistanceAlpha = (SplineParams.SplineHorizontalDistanceAlphaUnclamped + SplineParams.SplineVerticalDistanceAlphaUnclamped) * 0.5;
		// 		const float TunnelCenterDistanceAlpha = Math::Min(RawSplineDistanceAlpha, 1.0);
		// 		float GuideSplineStrengthAlpha = Settings.SplineGuidanceStrengthAlphaModifier.GetFloatValue(TunnelCenterDistanceAlpha, TunnelCenterDistanceAlpha);
		// 		GuideSplineStrengthAlpha = Settings.SplineGuidanceStrength.Lerp(Math::Clamp(GuideSplineStrengthAlpha, 0.0, 1.0));
		// 		if(GuideSplineStrengthAlpha > KINDA_SMALL_NUMBER)
		// 		{
		// 			FVector FuturePosition = Car.ActorLocation + (WantedMoveVelocity.GetSafeNormal() * WantedMoveVelocity.DotProduct(SplineParams.SplinePosition.WorldForwardVector) * 0.5);
		// 			FSkylineFlyingCarSplineParams FutureSplineParams;
		// 			Car.GetSplineDataAtPosition(FuturePosition, FutureSplineParams);

		// 			if(WantedMoveVelocity.DotProduct(SplineParams.DirToSpline) > -0.7)
		// 			{
		// 				FVector DirToSpline = (FutureSplineParams.SplinePosition.WorldLocation - Car.ActorLocation).GetSafeNormal();
		// 				DirToSpline = Math::Lerp(WantedMoveVelocity.GetSafeNormal(), DirToSpline, GuideSplineStrengthAlpha);
		// 				WantedMoveVelocity = Math::VInterpTo(WantedMoveVelocity.GetSafeNormal(), DirToSpline, DeltaTime, Settings.FreeFlyRotationInterpSpeed).GetSafeNormal() * WantedMoveVelocity.Size();
		// 			}
		// 		}
		// 	}
		// }
	}
}