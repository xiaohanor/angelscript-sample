class USkylineFlyingCarGotySplineMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarMovement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	default DebugCategory = n"FlyingCar";

	ASkylineFlyingCar Car;
	UHazeMovementComponent MoveComp;
	USkylineFlyingCarMovementData Movement;
	USkylineFlyingCarGotySettings Settings;
	bool bIsInsideTunnel = false;

	float CurrentMoveSpeed = 0.0;
	FRotator PreviousMeshRotation = FRotator::ZeroRotator;

	UHazeCrumbSyncedRotatorComponent CrumbedMeshRotation;

	float LastHopTimeStamp;

	bool bSplineHopBlocked;

	FHazeAcceleratedVector AccInput;

	// Holds interpolated car actor rotation, used for visuals (mesh rotation)
	FRotator InterpedActorRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Car = Cast<ASkylineFlyingCar>(Owner);
		Settings = USkylineFlyingCarGotySettings::GetSettings(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(USkylineFlyingCarMovementData);

		CrumbedMeshRotation = UHazeCrumbSyncedRotatorComponent::GetOrCreate(Car, n"MovementMeshRotation");
		CrumbedMeshRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (Car.ActiveHighway == nullptr)
			return false;

		if (Car.IsSplineHopping())
			return false;

		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (Car.ActiveHighway == nullptr)
			return true;

		if (Car.IsSplineHopping())
			return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FSkylineFlyingCarSplineParams SplineParams;
		Car.GetSplineDataAtPosition(Car.GetActorLocation(), SplineParams);
		CurrentMoveSpeed = Math::Max(Car.ActorVelocity.DotProduct(SplineParams.SplinePosition.WorldForwardVector), 1.0);

		PreviousMeshRotation = Car.MeshRoot.WorldRotation;
		InterpedActorRotation = Car.ActorRotation;

		// Don't allow spline hopping as soon as we got here
		Car.ApplyManeuverBlock(this);
		bSplineHopBlocked = true;

		// Trigger spline hopped event
		if (Car.bJustSplineHopped)
		{
			Car.bJustSplineHopped = false;
			USkylineFlyingCarEventHandler::Trigger_OnSplineHopEnd(Car);
			LastHopTimeStamp = Time::GameTimeSeconds;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bSplineHopBlocked)
		{
			Car.ClearManeuverBlock(this);
			bSplineHopBlocked = false;
		}

		if (Car.bCloseToSplineEdge)
		{
			Car.bCloseToSplineEdge = false;
			USkylineFlyingCarEventHandler::Trigger_OnCloseToEdgeEnd(Car);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FSkylineFlyingCarSplineParams SplineParams;
				Car.GetSplineDataAtPosition(Car.GetActorLocation(), SplineParams);
				FSplinePosition SplinePosition = SplineParams.SplinePosition;

				// We have reached the spline and can now start searching for splines again
				if(Car.bSelectNewHighwayIsblockedUntilCurrentIsReached && SplineParams.SplineHorizontalDistanceAlphaUnclamped <= 1.0 && SplineParams.SplineVerticalDistanceAlphaUnclamped <= 1.0)
				{
					Car.bSelectNewHighwayIsblockedUntilCurrentIsReached = false;
				}

				// Update the movement speed
				{
					float TargetMoveSpeed = Settings.SplineMoveSpeed * Car.ActiveHighway.MovementSpeedScale;
					if(Car.IsSplineHopping())
						TargetMoveSpeed *= Settings.SplineBoostSpeedMultiplier;

					if(TargetMoveSpeed > CurrentMoveSpeed)
						CurrentMoveSpeed = Math::FInterpTo(CurrentMoveSpeed, TargetMoveSpeed, DeltaTime, Settings.SplineMoveSpeedAcceleration);
					else if(SplineParams.SplineHorizontalDistanceAlphaUnclamped <= 2.0 && SplineParams.SplineVerticalDistanceAlphaUnclamped <= 2.0)
						CurrentMoveSpeed = Math::FInterpTo(CurrentMoveSpeed, TargetMoveSpeed, DeltaTime, Settings.SplineMoveSpeedDeceleration);
					else
						CurrentMoveSpeed = Math::FInterpTo(CurrentMoveSpeed, TargetMoveSpeed, DeltaTime, Settings.SplineMoveSpeedDeceleration * 0.5);
				}

				FVector Input = FVector(0.0, Car.YawInput, Car.PitchInput);

				AccInput.AccelerateTo(Input, 0.5, DeltaTime);

				Input = AccInput.Value;
				
				FRotator DeltaRotation = FRotator::ZeroRotator;

				// Update Yaw steering
				{
					const float TargetOrientationChange = Input.Y * Settings.YawRotationSpeed;	
					DeltaRotation.Yaw += TargetOrientationChange * Car.ActiveHighway.SteeringSpeedScale;
				}

				// Update Pitch steering
				{
					const float TargetOrientationChange = Input.Z * Settings.PitchRotationSpeed;	
					DeltaRotation.Pitch += TargetOrientationChange * Car.ActiveHighway.SteeringSpeedScale;
				}

				// Apply the look ahead distance
				SplinePosition.Move(Math::Max(Settings.SplineGuidanceDistance, 1.0));
				FRotator WantedMovementRotation = SplinePosition.WorldRotation.Rotator();
		
				// Setup the wanted steering orientation from the input
				// and the max we can deviate from the spline direction
				{
					WantedMovementRotation.Yaw += (Math::Sign(Input.Y) * Settings.MaxSplineOffsetSteeringAngle);
					WantedMovementRotation.Pitch += (Math::Sign(Input.Z) * Settings.MaxSplineOffsetSteeringAngle);
					WantedMovementRotation.Roll += (Math::Sign(Input.Y) * Settings.MaxSplineOffsetSteeringAngle);
				}

				// Apply the delta rotation speed
				{
					// Eman TODO: Lerping fucks up rotation when turning a tight corner, either make it visuals-only or increase lerp speed
					FRotator ActorRotation = Car.GetActorRotation();
					const float DeltaRotationYaw = Math::Abs(DeltaRotation.Yaw);
					const float DeltaRotationPitch = Math::Abs(DeltaRotation.Pitch);

					// Input rotation
					FRotator MovementInputRotation;
					MovementInputRotation.Yaw = Car.RotateAxisTowardTargetWithDelta(ActorRotation.Yaw, WantedMovementRotation.Yaw, DeltaRotationYaw);
					MovementInputRotation.Pitch = Car.RotateAxisTowardTargetWithDelta(ActorRotation.Pitch, WantedMovementRotation.Pitch, DeltaRotationPitch);
					MovementInputRotation.Roll = Math::FInterpTo(Car.MeshRoot.WorldRotation.Roll, WantedMovementRotation.Roll, DeltaTime, Settings.ReturnToIdleRotationSpeed * 1.5);

					// Spline guide rotation
					FRotator SplineGuideRotation;
					SplineGuideRotation.Yaw = Math::FInterpTo(ActorRotation.Yaw, WantedMovementRotation.Yaw, DeltaTime, Settings.ReturnToIdleRotationSpeed);
					SplineGuideRotation.Pitch = Math::FInterpTo(ActorRotation.Pitch, WantedMovementRotation.Pitch, DeltaTime, Settings.ReturnToIdleRotationSpeed);
					SplineGuideRotation.Roll = Math::FInterpTo(Car.MeshRoot.WorldRotation.Roll, WantedMovementRotation.Roll, DeltaTime, Settings.ReturnToIdleRotationSpeed * 1.5);

					float DurationSinceLastHop = Time::GameTimeSeconds - LastHopTimeStamp;
					float JustHoppedAlpha = Math::Pow(Math::Saturate(DurationSinceLastHop / Settings.SplineMergeGuidanceStrengthAccelerationDuration), 3);
					WantedMovementRotation = Math::LerpShortestPath(SplineGuideRotation, MovementInputRotation, JustHoppedAlpha);
				}

				WantedMovementRotation.Normalize();

				// Apply the mesh rotation and the fake mesh rotation
				{
					// WantedMeshRoot = WantedMovementRotation;
					// WantedMeshRoot += DeltaRotation * Settings.FakeMeshRotationAmount;
					// WantedMeshRoot.Normalize();

					// CrumbedMeshRotation.Value = Math::RInterpTo(PreviousMeshRotation, WantedMeshRoot, DeltaTime, /*Car.bIsSplineBoosting ? 30.0 : */ 10.0);

					UpdateMeshRotation(DeltaTime);
				}

				// Rotate the movement towards the wanted direction
				FRotator CurrentMovementRotation = WantedMovementRotation;
				FVector WantedMoveVelocity = CurrentMovementRotation.ForwardVector * CurrentMoveSpeed + MoveComp.GetPendingImpulse();

				// Constrain velocity to spline direction
				// Accelerate this instead?
				if (WantedMoveVelocity.GetSafeNormal().DotProduct(SplinePosition.WorldForwardVector) <= 0)
				{
					FVector SplineConstrainedVelocity = WantedMoveVelocity.ConstrainToDirection(SplinePosition.WorldForwardVector);
					WantedMoveVelocity -= SplineConstrainedVelocity;
					WantedMoveVelocity += SplinePosition.WorldForwardVector * SplineConstrainedVelocity.Size();
				}

				FVector FinalDelta = WantedMoveVelocity * DeltaTime;

				if(!Car.IsSplineHopping())
				{
					FVector FuturePosition = Car.ActorLocation + FinalDelta;
					FSkylineFlyingCarSplineParams FutureSplineParams;
					Car.GetSplineDataAtPosition(FuturePosition, FutureSplineParams);

					// Steer soft towards the highway
					FlyingCar::SteerTowardsHighway(Car, FutureSplineParams, Settings, FinalDelta);

					// Make sure we can never leave the spline, this shouldn't happen if HighwaySteer works properly
					if(!Car.bSelectNewHighwayIsblockedUntilCurrentIsReached)
						if (FlyingCar::ConstrainLocationToHighwayBounds(FutureSplineParams, FuturePosition))
							FinalDelta = FuturePosition - Car.ActorLocation;

					UpdateClosenessToEdge(FutureSplineParams);
				}

				// Finalize the movement rotation from the final location
				WantedMovementRotation = (FinalDelta - MoveComp.GetPendingImpulse() * DeltaTime * 0.8).ToOrientationRotator();
				CurrentMovementRotation = Math::RInterpTo(Car.ActorRotation, WantedMovementRotation, DeltaTime, Car.IsSplineDashing() ? 10.0 : 10.0); // Eman TODO: Decide on a dash behaviour
				CurrentMovementRotation = Math::RInterpConstantTo(CurrentMovementRotation, WantedMovementRotation, DeltaTime, 10.0);

				Movement.AddDeltaWithCustomVelocity(FinalDelta, WantedMoveVelocity);
				Movement.SetRotation(CurrentMovementRotation);
				Movement.BlockGroundTracingForThisFrame();

				if (bSplineHopBlocked && ActiveDuration >= Settings.SpecialManeuverCooldown)
				{
					Car.ClearManeuverBlock(this);
					bSplineHopBlocked = false;
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}

		if (!Car.IsSplineDashing())
			Car.MeshRoot.WorldRotation = CrumbedMeshRotation.Value;

		PreviousMeshRotation = Car.MeshRoot.WorldRotation;
	}

	void UpdateMeshRotation(float DeltaTime)
	{
		// Interpolate movement rotation
		InterpedActorRotation = Math::RInterpTo(InterpedActorRotation, Car.ActorRotation, DeltaTime, 15);

		// Calculate local mesh rotation
		FRotator MeshRotation = FRotator(Settings.PitchMeshRotation.UpdateAngle(Car.PitchInput, DeltaTime),
										 Settings.YawMeshRotation.UpdateAngle(Car.YawInput, DeltaTime),
										 Settings.RollMeshRotation.UpdateAngle(Car.YawInput, DeltaTime));

		// Brothers unite!
		CrumbedMeshRotation.Value = InterpedActorRotation + MeshRotation;
	}

	// Eman TODO: Move to flying car actor
	void UpdateClosenessToEdge(const FSkylineFlyingCarSplineParams& FutureSplineParams)
	{
		const float OuterRadius = 0.8;

		// We only support tunnel hopping
		if (FutureSplineParams.SplineVerticalDistanceAlphaUnclamped >= OuterRadius)
		{
			// We are close to edge
			if (!Car.bCloseToSplineEdge)
			{
				CrumbTriggerCloseToEdgeStart();
			}
		}
		else
		{
			// We are NOT close to edge
			if (Car.bCloseToSplineEdge)
			{
				CrumbTriggerCloseToEdgeEnd();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerCloseToEdgeStart()
	{
		Car.bCloseToSplineEdge = true;
		USkylineFlyingCarEventHandler::Trigger_OnCloseToEdgeStart(Car);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerCloseToEdgeEnd()
	{
		Car.bCloseToSplineEdge = false;
		USkylineFlyingCarEventHandler::Trigger_OnCloseToEdgeEnd(Car);
	}
}