class USlidingDiscMovementBoatCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;
	default CapabilityTags.Add(SlidingDiscTags::SlidingDiscMovement);
	default TickGroupOrder = 100;

	UHazeMovementComponent MovementComponent;
	USimpleMovementData Movement;
	ASlidingDisc Boat;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSimpleMovementData();
		Boat = Cast<ASlidingDisc>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;
		if (!Boat.bIsBoating)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;
		if (!Boat.bIsBoating)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Boat.Velocity = Boat.ActorVelocity;

	//	PrintToScreen("Speed: " + SpaceMav.Velocity.Size(), 0.0, FLinearColor::Green);

		if (MovementComponent.PrepareMove(Movement))
		{
				if (Boat.IgnoreCollisionBoat != nullptr)
					Movement.IgnoreActorForThisFrame(Boat.IgnoreCollisionBoat);
			if (HasControl())
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
									 + Boat.BoatGravity
									 + Boat.BuoyantForce
									 + Boat.StreamForce
									 - Boat.DragForce;

				FVector Delta = FVector::ZeroVector;
				Acceleration::ApplyAccelerationToVelocity(Boat.Velocity, Acceleration, DeltaTime, Delta);
				Boat.Velocity += Boat.ConsumeImpulse();
				Delta += Boat.Velocity * DeltaTime;

				FQuat Rotation = Boat.Pivot.ComponentQuat * FQuat(Boat.AngularVelocity.SafeNormal, Boat.AngularVelocity.Size() * DeltaTime);
				Boat.Pivot.SetWorldRotation(Rotation);

//				FQuat Rotation = Boat.ActorQuat * FQuat(Boat.AngularVelocity.SafeNormal, Boat.AngularVelocity.Size() * DeltaTime);
//				Movement.SetRotation(Rotation);
				Movement.AddDeltaWithCustomVelocity(Delta, Boat.Velocity);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(Movement);
		}
	}
};