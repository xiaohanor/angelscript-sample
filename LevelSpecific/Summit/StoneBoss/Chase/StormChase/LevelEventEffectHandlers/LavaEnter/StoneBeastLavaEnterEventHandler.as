struct FOnStoneBeastEnterLavaParams
{
	UPROPERTY()
	FVector Location;

	FOnStoneBeastEnterLavaParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UStoneBeastLavaEnterEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastEnter(FOnStoneBeastEnterLavaParams Params) {}
};