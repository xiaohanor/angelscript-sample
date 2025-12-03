UCLASS(Abstract)
class ASummitSacrificialBowl : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASummitMagicalPlatformActivator FruitRef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FruitRef.OnReachedDestination.AddUFunction(this, n"ActivateBowl");
		FruitRef.OnReset.AddUFunction(this, n"DeactivateBowl");
	}

	UFUNCTION()
	void ActivateBowl()
	{
		BP_ActivateBowl();
	}

	UFUNCTION()
	void DeactivateBowl()
	{
		BP_DeactivateBowl();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateBowl(){}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateBowl(){}

};
