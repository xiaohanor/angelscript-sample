event void FOnBoulderLiftingPlantInteractStopped();
event void FOnBoulderLiftingPlantInteractStarted();

class ATundraBoulderLiftingPlant : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent CrumbSyncedFloat;

	UPROPERTY()
	FOnBoulderLiftingPlantInteractStopped OnInteractStopped;

	UPROPERTY()
	FOnBoulderLiftingPlantInteractStopped OnInteractStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(CrumbFunction, BlueprintCallable)
	void CrumbStartRolling()
	{
		OnStartRolling();
	}
	
	UFUNCTION(BlueprintEvent)
	void OnStartRolling()
	{

	}

};