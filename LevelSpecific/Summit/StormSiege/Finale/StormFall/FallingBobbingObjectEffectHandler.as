struct FOnFallingBobbingObjectDestroyedParams
{
	UPROPERTY()
	FVector Location;

	FOnFallingBobbingObjectDestroyedParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UFallingBobbingObjectEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFallingBobbingDestroyed(FOnFallingBobbingObjectDestroyedParams Params) {}
};