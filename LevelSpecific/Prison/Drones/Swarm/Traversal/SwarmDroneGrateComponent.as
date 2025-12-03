class USwarmDroneGrateComponent : UHazeMovablePlayerTriggerComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Too magic?
		TArray<UMeshComponent> MeshComponents;
		Owner.GetComponentsByClass(MeshComponents);
		for (auto MeshComponent : MeshComponents)
			MeshComponent.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");
	}

	UFUNCTION(BlueprintOverride)
	bool CanTriggerForPlayer(AHazePlayerCharacter PlayerCharacter) const
	{
		UPlayerSwarmDroneComponent SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(PlayerCharacter);
		if (SwarmDroneComponent == nullptr)
			return false;

		if (!SwarmDroneComponent.bSwarmModeActive)
			return false;

		return true;
	}

	// Just disable actor collisions for now
	UFUNCTION(BlueprintOverride)
	void OnPlayerEnteredTrigger(AHazePlayerCharacter PlayerCharacter)
	{
		UPlayerMovementComponent MovementComponent = UPlayerMovementComponent::Get(PlayerCharacter);
		if (MovementComponent != nullptr)
			MovementComponent.AddMovementIgnoresActor(this, Owner);
	}

	// Reenable them
	UFUNCTION(BlueprintOverride)
	void OnPlayerLeftTrigger(AHazePlayerCharacter PlayerCharacter)
	{
		UPlayerMovementComponent MovementComponent = UPlayerMovementComponent::Get(PlayerCharacter);
		if (MovementComponent != nullptr)
			MovementComponent.RemoveMovementIgnoresActor(this);
	}
}