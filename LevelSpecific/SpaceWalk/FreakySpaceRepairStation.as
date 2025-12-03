event void FonRepaired();

class AFreakySpaceRepairStation : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor InteractionSpot;

	UPROPERTY()
	FonRepaired RepairsDone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void BP_RepairFinished()
	{
		RepairsDone.Broadcast();
	}
};