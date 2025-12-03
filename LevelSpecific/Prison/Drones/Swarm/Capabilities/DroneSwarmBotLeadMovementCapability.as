class UDroneSwarmBotLeadMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	AHazePlayerCharacter Player;
	ADroneSwarmBotLead BotLeadOwner;

	UHazeMovementComponent PlayerMovementComponent;
	UPlayerSwarmDroneComponent SwarmDroneComponent;

	UHazeMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner.AttachParentActor);
		PlayerMovementComponent = UHazeMovementComponent::Get(Player);
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Player);

		BotLeadOwner = Cast<ADroneSwarmBotLead>(Owner);
		MovementComponent = BotLeadOwner.MovementComponent;
		MoveData = MovementComponent.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Eman TODO: Activate only when swarm is active
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Debug::DrawDebugSphere(Owner.ActorLocation, BotLeadOwner.CollisionShape.SphereRadius, 10, FLinearColor::DPink, 1.0);

		if (!MovementComponent.Velocity.IsNearlyZero())
			BotLeadOwner.SetMovementFacingDirection(MovementComponent.Velocity.GetSafeNormal());

		if (!MovementComponent.PrepareMove(MoveData))
			return;

		// Player movement
		FVector Velocity = PlayerMovementComponent.Velocity;

		MoveData.InterpRotationToTargetFacingRotation(20.0);

		// MoveData.AddDelta(FVector::ForwardVector );

		FVector Gravity = -MovementComponent.WorldUp * Drone::Gravity;
		MoveData.AddAcceleration(Gravity);


		MoveData.AddVelocity(Velocity);
		MovementComponent.ApplyMove(MoveData);
	}
}