class USkylineBossTankMovementCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankMovement);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
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
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		FVector AngularAcceleration = BossTank.ConsumeTorque()
									- BossTank.AngularVelocity * BossTank.AngularDrag;

		FVector DeltaRotation;
		Acceleration::ApplyAccelerationToVelocity(BossTank.AngularVelocity, AngularAcceleration, DeltaTime, DeltaRotation);
		DeltaRotation += BossTank.AngularVelocity * DeltaTime;

		BossTank.AngularVelocity += AngularAcceleration * DeltaTime;

		FQuat Rotation = BossTank.ActorQuat * FQuat(DeltaRotation.SafeNormal, DeltaRotation.Size());

		FVector Acceleration = BossTank.ConsumeForce()
							 - BossTank.Velocity * BossTank.Drag;

		FVector DeltaMove;
		Acceleration::ApplyAccelerationToVelocity(BossTank.Velocity, Acceleration, DeltaTime, DeltaMove);
		DeltaMove += BossTank.Velocity * DeltaTime;

		// See if new location is outside constraint and constrain it
		FVector NewLocation = BossTank.ActorLocation + DeltaMove;
		FVector ConstraintOriginToNewLocation = NewLocation - BossTank.ConstraintRadiusOrigin.ActorLocation;

		if (ConstraintOriginToNewLocation.Size() > BossTank.ConstraintRadius)
		{
			NewLocation = BossTank.ConstraintRadiusOrigin.ActorLocation + ConstraintOriginToNewLocation.SafeNormal * BossTank.ConstraintRadius;
			DeltaMove = NewLocation - BossTank.ActorLocation;
		}

		BossTank.SetActorLocationAndRotation(BossTank.ActorLocation + DeltaMove, Rotation);
	}

	void TickRemote(float DeltaTime)
	{
		const FHazeSyncedActorPosition& Position = BossTank.SyncedActorPositionComp.GetPosition();	
		BossTank.SetActorLocationAndRotation(Position.WorldLocation, Position.WorldRotation);
		BossTank.SetActorVelocity(Position.WorldVelocity);
	}
}