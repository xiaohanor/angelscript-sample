UCLASS(Abstract)
class APrisonDoubleElectricPoleHazard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintEvent)
	void Activate()
	{
	}

	UFUNCTION(BlueprintEvent)
	void Deactivate()
	{
	}

	UFUNCTION(BlueprintEvent)
	void Stop()
	{
	}
};