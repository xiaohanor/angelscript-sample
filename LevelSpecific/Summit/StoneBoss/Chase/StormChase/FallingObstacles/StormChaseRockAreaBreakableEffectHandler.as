struct FRockAreaDestroyedParams
{
	UPROPERTY()
	FVector Location;

	FRockAreaDestroyedParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UStormChaseRockAreaBreakableEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRockAreaDestroyed(FRockAreaDestroyedParams Params) {}
};