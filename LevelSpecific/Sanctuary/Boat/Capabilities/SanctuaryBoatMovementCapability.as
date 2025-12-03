class USanctuaryBoatMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(SanctuaryBoatTags::Boat);

	default TickGroup = EHazeTickGroup::Movement;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	UHazeCrumbSyncedRotatorComponent SyncedPivotRotation;

	ASanctuaryBoat Boat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
		Boat = Cast<ASanctuaryBoat>(Owner);
		SyncedPivotRotation = UHazeCrumbSyncedRotatorComponent::Create(Boat, n"SyncedPivotRotation");
		SyncedPivotRotation.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SyncedPivotRotation.SetValue(Boat.Pivot.WorldRotation);
		SyncedPivotRotation.SnapRemote();
		SyncedPivotRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SyncedPivotRotation.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Boat.Velocity = Boat.ActorVelocity;

	//	PrintToScreen("Speed: " + SpaceMav.Velocity.Size(), 0.0, FLinearColor::Green);

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				{
					FVector GrabForce = Boat.GrabForce;

					FVector AngularAcceleration = Boat.FloatingTorque
												+ Boat.LinearToTorque(Boat.ForceAnchorComp.WorldLocation, GrabForce)
												+ Boat.PlayerImpactTorque
												- Boat.AngularDragTorque;

					Boat.AngularVelocity += AngularAcceleration * DeltaTime
										+ Boat.ConsumeAngularImpulse();
					FVector Acceleration = GrabForce
										+ Boat.PlayerImpactForce
										+ Boat.Gravity
										+ Boat.BuoyantForce
										+ Boat.StreamForce
										- Boat.DragForce;

					FVector Delta = FVector::ZeroVector;
					Acceleration::ApplyAccelerationToVelocity(Boat.Velocity, Acceleration, DeltaTime, Delta);
					Boat.Velocity += Boat.ConsumeImpulse();
					Delta += Boat.Velocity * DeltaTime;

					FQuat Rotation = Boat.Pivot.ComponentQuat * FQuat(Boat.AngularVelocity.SafeNormal, Boat.AngularVelocity.Size() * DeltaTime);
					SyncedPivotRotation.SetValue(Rotation.Rotator());

					if (Boat.SuperHackySnapToDisc != nullptr)
					{
						FVector ToDiscDelta = Boat.SuperHackySnapToDisc.ActorLocation - Boat.ActorLocation;
						Movement.IgnoreActorForThisFrame(Boat.SuperHackySnapToDisc);
						Movement.AddDeltaWithCustomVelocity(ToDiscDelta, Boat.Velocity);
					}
					else
						Movement.AddDeltaWithCustomVelocity(Delta, Boat.Velocity);
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			Boat.Pivot.SetWorldRotation(SyncedPivotRotation.Value);

			// ColorDebug::DrawTintedTransform(Boat.Pivot.WorldLocation, Boat.Pivot.WorldRotation, ColorDebug::Red);
			// ColorDebug::DrawTintedTransform(Boat.ActorLocation, Boat.ActorRotation, ColorDebug::White, 400);
		}
	}
};