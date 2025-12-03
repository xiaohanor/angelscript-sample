struct FMeltdownScreenWalkWaterfallPlatformStomp
{
	FMeltdownScreenWalkWaterfallPlatformStomp(UBillboardComponent _StompLocation)
	{
		StompLocation = _StompLocation;
	}

	UPROPERTY()
	UBillboardComponent StompLocation;

}

struct FMeltdownScreenWalkWaterfallPlatformWater
{
		FMeltdownScreenWalkWaterfallPlatformWater(UBillboardComponent _WaterLocation)
	{
		WaterLocation = _WaterLocation;
	}

	UPROPERTY()
	UBillboardComponent WaterLocation;
}

UCLASS(Abstract)
class UMeltdownScreenWalkWaterfallPlatformEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StompEffect(FMeltdownScreenWalkWaterfallPlatformStomp Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WaterSplashStart(FMeltdownScreenWalkWaterfallPlatformWater WaterParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WaterSplashStop(FMeltdownScreenWalkWaterfallPlatformWater WaterParams) {}
};