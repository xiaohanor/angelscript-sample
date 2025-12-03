struct FSwarmDroneGliderCannonFireParams
{
	FVector Velocity;
	FVector MuzzleLocation;
}

class ASwarmDroneGliderCannon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UStaticMeshComponent CannonMesh;

	UPROPERTY(DefaultComponent, Attach = CannonMesh)
	USceneComponent CannonMuzzle;

	UPROPERTY(DefaultComponent)
	UDroneSwarmMovementZoneComponent MoveZone;


	UPROPERTY(EditAnywhere)
	const float LaunchForce = 5000.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveZone.OnPlayerEnter.AddUFunction(this, n"OnSwarmWithinRange");
	}

	void FirePlayerSwarmDrone(AHazePlayerCharacter Player)
	{
		UPlayerSwarmDroneGliderComponent SwarmDroneGliderComponent = UPlayerSwarmDroneGliderComponent::Get(Player);
		if (SwarmDroneGliderComponent == nullptr)
			return;

		FSwarmDroneGliderCannonFireParams FireParams;
		FireParams.Velocity = CannonMesh.ForwardVector * LaunchForce;
		FireParams.MuzzleLocation = CannonMuzzle.WorldLocation;
		SwarmDroneGliderComponent.StartGliding(FireParams);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSwarmWithinRange(AHazePlayerCharacter Player)
	{
		FirePlayerSwarmDrone(Player);
	}
}