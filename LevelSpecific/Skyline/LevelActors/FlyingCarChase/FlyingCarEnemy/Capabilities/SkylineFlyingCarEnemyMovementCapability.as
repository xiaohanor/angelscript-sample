class USkylineFlyingCarEnemyMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingCarEnemyMovement");

	default TickGroup = EHazeTickGroup::Movement;

	ASkylineFlyingCarEnemy FlyingCarEnemy;

	UHazeMovementComponent MovementComponent;

	USkylineFlyingCarEnemyMovementData Movement;

	UHazeActorRespawnableComponent RespawnableComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingCarEnemy = Cast<ASkylineFlyingCarEnemy>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupMovementData(USkylineFlyingCarEnemyMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Direction = Owner.ActorForwardVector;
		FVector Up = FVector::UpVector;
		float TargetSpeed = FlyingCarEnemy.Acceleration;

		if (FlyingCarEnemy.Spline != nullptr)
		{
			auto& Spline = FlyingCarEnemy.Spline;
//			auto& Spline = RespawnableComponent.SpawnParameters.Spline;

			auto SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation + MovementComponent.Velocity);


 			// Slow down and stop when reached end of spline
			const float SlowDownDistance = 1000;
			if (SplinePosition.CurrentSplineDistance >= Spline.SplineLength)
			{
				if (FlyingCarEnemy.bShouldExplodeAtEndOfSpline)
					FlyingCarEnemy.Explode();
				return;
			}
			else if (SplinePosition.CurrentSplineDistance >= Spline.SplineLength - SlowDownDistance)
			{
				float RemainingDist = Spline.SplineLength - SlowDownDistance;
				float SlowDownFraction = RemainingDist / SlowDownDistance;
				TargetSpeed *= SlowDownFraction;
			}


			FVector Location = SplinePosition.WorldLocation;
			Location += SplinePosition.WorldTransformNoScale.TransformVectorNoScale(FlyingCarEnemy.DesiredOffsetOnSpline);

			Up = SplinePosition.WorldUpVector;

			Direction = (Location - Owner.ActorLocation).GetSafeNormal()
					  + SplinePosition.WorldForwardVector;

			Direction.Normalize();
		}

		FVector Torque = FlyingCarEnemy.ActorTransform.InverseTransformVectorNoScale(FlyingCarEnemy.ActorForwardVector.CrossProduct(Direction) * 10.0)
					   + FlyingCarEnemy.ActorTransform.InverseTransformVectorNoScale(FlyingCarEnemy.ActorUpVector.CrossProduct(Up) * 10.0)
					   + FlyingCarEnemy.ActorTransform.InverseTransformVectorNoScale(FlyingCarEnemy.ActorForwardVector.CrossProduct(FlyingCarEnemy.Avoidance) * 5.0)
					   - FlyingCarEnemy.AngularVelocity * FlyingCarEnemy.AngularDrag;

		FlyingCarEnemy.AngularVelocity += Torque * DeltaTime;

		FQuat DeltaRotation = FQuat(FlyingCarEnemy.AngularVelocity.GetSafeNormal(), FlyingCarEnemy.AngularVelocity.Size() * DeltaTime);


		if (FlyingCarEnemy.FollowTarget != nullptr)
		{
			TargetSpeed = FlyingCarEnemy.FollowTarget.ActorVelocity.Size();

			FVector ToTarget = Owner.ActorTransform.InverseTransformVectorNoScale(FlyingCarEnemy.FollowTarget.ActorLocation - Owner.ActorLocation);

			FlyingCarEnemy.CurrentDistanceToTarget = (FlyingCarEnemy.FollowTarget.ActorLocation - Owner.ActorLocation).Size();
			float Adjustment = FlyingCarEnemy.CurrentDistanceToTarget - FlyingCarEnemy.DistanceFromTarget;

	//		PrintScaled("Adjustment: " + ToTarget.X, 0.0, FLinearColor::Green, 2.0);

			TargetSpeed += (ToTarget.X + FlyingCarEnemy.DistanceFromTarget);

	//		PrintScaled("TargetSpeed: " + TargetSpeed, 0.0, FLinearColor::Green, 2.0);
		}

		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;

			FVector Acceleration = Direction * (TargetSpeed * FlyingCarEnemy.Drag)
								 + FlyingCarEnemy.Avoidance * 3000.0
								 - Velocity * FlyingCarEnemy.Drag;

			Velocity += Acceleration * DeltaTime;

			Movement.AddVelocity(Velocity);

			Movement.SetRotation(Owner.ActorQuat * DeltaRotation);

			Movement.AddPendingImpulses();

			MovementComponent.ApplyMove(Movement);
		}

		TickMeshRotation(DeltaTime);
	}

	/**
	 * Handles rotation of the VisualRoot while moving
	 */
	void TickMeshRotation(float DeltaTime)
	{
		// Convert our acceleration/deceleration to an angular impulse
		FVector VelocityDiff = (MovementComponent.Velocity - MovementComponent.PreviousVelocity);
		FVector WorldAngularImpulse = FVector::UpVector.CrossProduct(VelocityDiff);
		const FVector RelativeAngularImpulse = FlyingCarEnemy.ActorTransform.InverseTransformVectorNoScale(WorldAngularImpulse);
		float AngularImpulseMagnitude = RelativeAngularImpulse.Size() * SkylineFlyingCarEnemy::AngularImpulseFromMovement;

		// Prevent the impulse from going loco
		const float Limit = Math::DegreesToRadians(SkylineFlyingCarEnemy::AngularImpulseFromMovementLimitDegrees);
		AngularImpulseMagnitude = Math::Clamp(AngularImpulseMagnitude, -Limit, Limit);

		FQuat TargetRotation = FQuat(RelativeAngularImpulse.GetSafeNormal(), AngularImpulseMagnitude);

		if(FlyingCarEnemy.bShouldLookAtPlayer)
		{
			FQuat LookAtRotation = FQuat::MakeFromX(Game::Mio.ActorLocation - FlyingCarEnemy.ActorLocation);
			FQuat RelativeLookAtRotation = FlyingCarEnemy.ActorTransform.InverseTransformRotation(LookAtRotation);
			TargetRotation = FQuat::ApplyDelta(TargetRotation, RelativeLookAtRotation);
		}

		FlyingCarEnemy.AccVisualRotation.SpringTo(
			TargetRotation,
			SkylineFlyingCarEnemy::AngularImpulseFromMovementStiffness,
			SkylineFlyingCarEnemy::AngularImpulseFromMovementDamping,
			DeltaTime
		);

		FlyingCarEnemy.VisualRoot.SetRelativeRotation(FlyingCarEnemy.AccVisualRotation.Value);
	}
}