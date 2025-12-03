class USkylineGeckoMoveToLocationComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");	
	}

	UPROPERTY()
	bool bMoveToLocation;

	UPROPERTY()
	FVector Location;

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		bMoveToLocation = false;
	}
}