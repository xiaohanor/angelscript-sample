struct FStormEventTopplingMountainsParams
{
	UPROPERTY()
	FVector Location;

	FStormEventTopplingMountainsParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UStormTopplingMountainsEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMountainsToppling(FStormEventTopplingMountainsParams Params)
	{
	}
};