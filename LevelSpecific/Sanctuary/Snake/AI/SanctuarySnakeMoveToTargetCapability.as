class USanctuarySnakeMoveToTargetCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 99;
	default CapabilityTags.Add(n"SanctuarySnake");
	default CapabilityTags.Add(n"SanctuarySnakeFollowTarget");

	UHazeMovementComponent MovementComponent;
	USweepingMovementData Movement;

	USanctuarySnakeSettings Settings;

	USanctuarySnakeComponent SanctuarySnakeComponent;
	USanctuarySnakeSplineFollowComponent SplineFollowComponent;

	ASanctuarySnake Snake;

	FVector CustomWorldUp = FVector::UpVector;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSweepingMovementData();
		Settings = USanctuarySnakeSettings::GetSettings(Owner);

		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);
		SplineFollowComponent = USanctuarySnakeSplineFollowComponent::Get(Owner);

		Snake = Cast<ASanctuarySnake>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SanctuarySnakeComponent.bFollowTarget)
			return false;

		if(SanctuarySnakeComponent.Target == nullptr)
			return false;

		if(MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SanctuarySnakeComponent.bFollowTarget)
			return true;

		if(SanctuarySnakeComponent.Target == nullptr)
			return true;

		if(MovementComponent.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Snake.AddMovementAlignsWithGroundContact(this);
	
		TargetLocation = SanctuarySnakeComponent.Target.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Snake.RemoveMovementAlignsWithGroundContact(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TargetLocation = Math::Lerp(TargetLocation, SanctuarySnakeComponent.Target.ActorLocation, 50.0 * DeltaTime);

		if(!MovementComponent.PrepareMove(Movement, MovementComponent.GroundContact.Normal))
			return;

		if(HasControl())
		{
			FVector ToTarget = (TargetLocation - Snake.ActorLocation).GetSafeNormal();

			float ToTargetDot = ToTarget.DotProduct(Snake.Pivot.ForwardVector);

		//	Debug::DrawDebugLine(Snake.ActorLocation, Snake.ActorLocation + Snake.Pivot.ForwardVector * 2000.0, FLinearColor::LucBlue, 10.0, 0.0);
		//	Debug::DrawDebugLine(Snake.ActorLocation, Snake.ActorLocation + ToTarget * 2000.0, FLinearColor::Green, 10.0, 0.0);

		//	Debug::DrawDebugPoint(TargetLocation, 50.0, FLinearColor::Green, 0.0);

		//	Debug::DrawDebugArc(90.0, Owner.ActorLocation, 2000.0, Snake.Pivot.ForwardVector, FLinearColor::Red, 10.0, SanctuarySnakeComponent.WorldUp, 16, 0.0, true, 0.0);

		//	PrintScaled("TargetDot: " + ToTargetDot, 0.0, FLinearColor::Green, 3.0);

			if (ToTargetDot < 0.7)
			{
				auto CurrentPlayerTarget = Cast<AHazePlayerCharacter>(SanctuarySnakeComponent.Target);
				if (CurrentPlayerTarget != nullptr)
				{
					SanctuarySnakeComponent.Target = CurrentPlayerTarget.OtherPlayer;
				}
			}

			FVector Velocity = MovementComponent.Velocity;
			Velocity += ToTarget * Settings.Acceleration * 1.5 * DeltaTime;
			Velocity += -MovementComponent.WorldUp * Settings.Gravity * DeltaTime;
			Velocity -= Velocity * Settings.Drag * DeltaTime;

		//	Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + Velocity * 1.0, FLinearColor::Yellow, 10.0, 0.0);

			Movement.AddVelocity(Velocity);
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MovementComponent.ApplyMove(Movement);

		SanctuarySnakeComponent.WorldUp = MovementComponent.WorldUp;
	
		if (ActiveDuration > 8.0)
		{
			SanctuarySnakeComponent.bFollowTarget = false;
			SanctuarySnakeComponent.bBurrow = true;
		}
	}
}