struct FBurrowingAlienOnActivatedParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UBurrowingAlienEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBurrowActivated(FBurrowingAlienOnActivatedParams Params) {}
}