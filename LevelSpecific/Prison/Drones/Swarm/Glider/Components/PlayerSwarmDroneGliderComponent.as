class UPlayerSwarmDroneGliderComponent : UActorComponent
{
	access SwarmDroneGliderSystem = private, USwarmDroneGliderCapability;
	access : SwarmDroneGliderSystem
	bool bGliding;

	FVector InitialVelocity;

	void StartGliding(FSwarmDroneGliderCannonFireParams InitialGlideParams)
	{
		// UPlayerMovementComponent MovementComponent = UPlayerMovementComponent::Get(Owner);

		AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerOwner.TeleportActor(InitialGlideParams.MuzzleLocation, FRotator::ZeroRotator, this);
		PlayerOwner.SetActorVelocity(InitialGlideParams.Velocity);
		bGliding = true;
	}

	UFUNCTION()
	bool IsGliding()
	{
		return bGliding;
	}
}