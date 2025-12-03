class UIslandDyadLaserComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	FIslandDyadLaserAimingLocations AimingLocation;

	AAIIslandDyad OtherDyad;
	bool bPrimaryDyad;
	bool bCanConnect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UBasicAIHealthComponent::Get(Owner).OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		bCanConnect = false;
	}
}

struct FIslandDyadLaserAimingLocations
{
	UPROPERTY(BlueprintReadOnly)
	FVector StartLocation;
	UPROPERTY(BlueprintReadOnly)
	FVector EndLocation;
}