class UHoverboardMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default CapabilityTags.Add(n"HoverboardMovement");

	UHazeMovementComponent MovementComponent;
	USimpleMovementData Movement;

	AHoverboard Hoverboard;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSimpleMovementData();
		Hoverboard = Cast<AHoverboard>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Hoverboard.bActive)
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Hoverboard.bActive)
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TurnForce;
		FQuat TargetRotation = Hoverboard.ActorQuat;

		TurnForce = MovementComponent.WorldUp.CrossProduct(MovementComponent.Velocity).GetSafeNormal() * MovementComponent.Velocity.Size() * 1.3 * Hoverboard.Lean.X;

		if (MovementComponent.HasGroundContact())
		{
			TargetRotation = FQuat::MakeFromZX(MovementComponent.GroundContact.Normal, MovementComponent.Velocity);
		}
		else
		{
			FVector HorizontalVelocity = MovementComponent.Velocity.VectorPlaneProject(MovementComponent.WorldUp);

			if(!HorizontalVelocity.IsNearlyZero())
			{
				TargetRotation = FQuat::MakeFromXZ(HorizontalVelocity, Hoverboard.Pivot.UpVector);
			}
		}

		Hoverboard.Pivot.SetWorldRotation(FQuat::Slerp(Hoverboard.Pivot.ComponentQuat, TargetRotation, 10.0 * DeltaTime));
		FVector Acceleration = Hoverboard.Gravity * MovementComponent.GravityMultiplier
							 + TurnForce
							 + Hoverboard.Pivot.ForwardVector * 2200.0 * (Hoverboard.bBoost ? 5.0 : 1.0)
							 - MovementComponent.Velocity * Hoverboard.Drag;

		//So we don't go down hills too fast
		FVector Velocity = MovementComponent.Velocity.GetClampedToMaxSize(3000.0);

		if(MovementComponent.PrepareMove(Movement))
		{
			Movement.AddVelocity(Velocity);
			Movement.AddAcceleration(Acceleration);
		//	Movement.SetRotation(Rotation);

			MovementComponent.ApplyMove(Movement);
		}

	}	
}