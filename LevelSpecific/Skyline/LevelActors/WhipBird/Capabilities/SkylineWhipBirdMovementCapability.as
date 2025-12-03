class USkylineWhipBirdMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineWhipBirdMovement");

	default TickGroup = EHazeTickGroup::Movement;

	ASkylineWhipBird WhipBird;

	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipBird = Cast<ASkylineWhipBird>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
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
		WhipBird.bIsFlying = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WhipBird.bIsFlying = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		WhipBird.Velocity = WhipBird.ActorVelocity;

		FVector Acceleration = WhipBird.ConsumeForce()
					 		 - WhipBird.Velocity * WhipBird.Drag;

		WhipBird.Velocity += Acceleration * DeltaTime;

		FVector DeltaMove = WhipBird.Velocity * DeltaTime;

		auto Rotation = FQuat::Slerp(WhipBird.ActorQuat, DeltaMove.ToOrientationQuat(), 5.0 * DeltaTime);
		WhipBird.SetActorRotation(Rotation);

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddVelocity(WhipBird.Velocity);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);

			if (MoveComp.HasAnyValidBlockingImpacts() && WhipBird.bIsThrown)
			{
			//	Animals are safe in this game
			//	WhipBird.Splat(MoveComp.AllImpacts[0].ImpactNormal);
			}
		}
	}
};