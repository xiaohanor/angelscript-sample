class UCutsceneSwarmDroneDebugCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ACutsceneSwarmDrone SwarmDrone;

	FVector PreviousLocation = FVector::ZeroVector;
	FVector InitialLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDrone = Cast<ACutsceneSwarmDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousLocation = InitialLocation = SwarmDrone.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// PreviousLocation = SwarmDrone.ActorLocation;

		// FVector Offset = SwarmDrone.ActorForwardVector * Math::Sin(Time::GameTimeSeconds * 0.5) * 500;
		// SwarmDrone.SetActorLocation(InitialLocation + Offset);

		// SwarmDrone.ActorVelocity = (SwarmDrone.ActorLocation - PreviousLocation) / DeltaTime;

		UPlayerSwarmDroneComponent PlayerSwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Game::Mio);
		if (PlayerSwarmDroneComponent != nullptr)
		{
			SwarmDrone.ActorVelocity = PlayerSwarmDroneComponent.Owner.ActorVelocity;
			SwarmDrone.SetActorLocation(PlayerSwarmDroneComponent.Owner.ActorLocation);

			FCutsceneSwarmDroneMoveData MoveData;
			MoveData.DeltaTime = DeltaTime;
			SwarmDrone.MovementResponseComponent.UpdateMovement(MoveData);
		}
	}
}