event void FOnGrowingPlantInteractStopped();
event void FOnGrowingPlantInteractStarted();

class ATundraGrowingPlant : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent CrumbSyncedFloat;

	UPROPERTY()
	FOnGrowingPlantInteractStopped OnInteractStopped;

	UPROPERTY()
	FOnGrowingPlantInteractStopped OnInteractStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
	}
};