struct FMeltdownFlipPlatformImpactLocation
{
	FMeltdownFlipPlatformImpactLocation(USceneComponent _Platform)
	{
		Platform = _Platform;
	}

	UPROPERTY()
	USceneComponent Platform;
}

UCLASS(Abstract)
class UMeltdownScreenWalkFlipPlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FMeltdownFlipPlatformImpactLocation Params) {}
};