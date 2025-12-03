struct FMeltableCounterWeightParams
{
	UPROPERTY()
	FVector Location;

	FMeltableCounterWeightParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UMeltableCounterWeightEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedFalling()
	{
	}

	//For when the weight drops initially after being activated
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedWeightDrop(FMeltableCounterWeightParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedWeightDrop(FMeltableCounterWeightParams Params) {}
};