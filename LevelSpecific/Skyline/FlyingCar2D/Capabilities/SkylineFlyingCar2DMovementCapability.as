class USkylineFlyingCar2DMovementCapability : UHazeCapability
{
	ASkylineFlyingCar2D FlyingCar2D;

	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingCar2D = Cast<ASkylineFlyingCar2D>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSweepingMovementData();
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
	void TickActive(float DeltaTime)
	{
		FVector InputVector;

		if (FlyingCar2D.bTopDown)
			InputVector = FVector(-FlyingCar2D.Input.Y, FlyingCar2D.Input.X, 0.0);
		else
			InputVector = FVector(FlyingCar2D.Input.X, 0.0, FlyingCar2D.Input.Y);

		InputVector = FlyingCar2D.ActorTransform.TransformVectorNoScale(InputVector);

//		Debug::DrawDebugLine(FlyingCar2D.ActorLocation, FlyingCar2D.ActorLocation + InputVector * 300.0, FLinearColor::Green, 10.0, 0.0);

		FVector Thruster = FlyingCar2D.VisualRoot.WorldTransform.InverseTransformVectorNoScale(FVector(0.0, FlyingCar2D.Input.X, 0.0) * 5.0);

//		Thruster *= Math::Max(1.0 - (FlyingCar2D.ActorVelocity.Size() / 10.0), 0.0);

		FVector Torque = FlyingCar2D.ActorTransform.InverseTransformVectorNoScale(FlyingCar2D.VisualRoot.RightVector.CrossProduct(FlyingCar2D.ActorRightVector) * 10.0)
					   + FlyingCar2D.ActorTransform.InverseTransformVectorNoScale(FlyingCar2D.VisualRoot.UpVector.CrossProduct(FlyingCar2D.MovementWorldUp) * 10.0)
					   + FlyingCar2D.VisualRoot.ForwardVector.CrossProduct(InputVector) * 4.0
					   - FlyingCar2D.AngularVelocity * FlyingCar2D.AngularDrag;

		FlyingCar2D.AngularVelocity += Torque * DeltaTime;

		FQuat DeltaRotaion = FQuat(FlyingCar2D.AngularVelocity.GetSafeNormal(), FlyingCar2D.AngularVelocity.Size() * DeltaTime);

		FlyingCar2D.VisualRoot.AddLocalRotation(DeltaRotaion);

		if(MovementComponent.PrepareMove(Movement))
		{
			FVector Velocity = MovementComponent.Velocity;

			FVector Acceleration = InputVector * FlyingCar2D.Acceleration
								 - Velocity * FlyingCar2D.Drag;

			Velocity += Acceleration * DeltaTime;

			Movement.AddVelocity(Velocity);
			MovementComponent.ApplyMove(Movement);
		}
	}
}