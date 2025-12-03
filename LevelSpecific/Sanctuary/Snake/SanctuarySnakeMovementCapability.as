class USanctuarySnakeMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;
	default CapabilityTags.Add(n"SanctuarySnake");
	default CapabilityTags.Add(n"SanctuarySnakeRiderMovement");

	UHazeMovementComponent MovementComponent;
	USweepingMovementData Movement;
//	USteppingMovementData Movement;

	USanctuarySnakeSettings Settings;

	USanctuarySnakeComponent SanctuarySnakeComponent;

	ASanctuarySnake Snake;

	FVector CustomWorldUp = FVector::UpVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSweepingMovementData();
//		Movement = MovementComponent.SetupSteppingMovementData();
		Settings = USanctuarySnakeSettings::GetSettings(Owner);

		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);

		Snake = Cast<ASanctuarySnake>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SanctuarySnakeComponent.bHasRider)
			return false;

		if(MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SanctuarySnakeComponent.bHasRider)
			return true;

		if(MovementComponent.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Snake.AddMovementAlignsWithGroundContact(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Snake.RemoveMovementAlignsWithGroundContact(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MovementComponent.PrepareMove(Movement, MovementComponent.GroundContact.Normal))
			return;

//		CustomWorldUp = CustomWorldUp.SlerpTowards(MovementComponent.GroundImpact.Normal, 3.0 * DeltaTime);
//		Snake.Pivot.SetWorldRotation(FQuat::MakeFromZX(CustomWorldUp, MovementComponent.Velocity));

		if(HasControl())
		{
			FVector Velocity = MovementComponent.Velocity;
			Velocity += MovementComponent.MovementInput * Settings.Acceleration * DeltaTime;
			Velocity += -MovementComponent.WorldUp * Settings.Gravity * DeltaTime;
			Velocity -= Velocity * Settings.Drag * DeltaTime;

			FVector VerticalVelocity = CustomWorldUp * Velocity.DotProduct(CustomWorldUp);
			FVector HorizontalVelocity = Velocity - VerticalVelocity;

		//	Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Velocity * 1.0, FLinearColor::Yellow, 10.0, 0.0);

			//Movement.AddVelocity(Velocity);
			Movement.AddVelocity(Velocity);
//			Movement.AddGravityAcceleration();
//			Movement.AddHorizontalVelocity(HorizontalVelocity);
		//	Movement.AddVerticalVelocity(VerticalVelocity);
	
		//	Movement.AddGravityAcceleration();
		//	Movement.AddHorizontalVelocity(HorizontalVelocity);
		//	Movement.AddVerticalVelocity(VerticalVelocity);
		//	Movement.SetRotation(Velocity.VectorPlaneProject(MovementComponent.WorldUp).Rotation());
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MovementComponent.ApplyMove(Movement);

		SanctuarySnakeComponent.WorldUp = MovementComponent.WorldUp;
//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + MovementComponent.MovementInput * 500.0, FLinearColor::Purple, 10.0, 0.0);
//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + CustomWorldUp * 1000.0, FLinearColor::Purple, 10.0, 0.0);

//		Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + MovementComponent.WorldUp * 400.0, FLinearColor::Blue, 5.0, 0.0);
	}
}