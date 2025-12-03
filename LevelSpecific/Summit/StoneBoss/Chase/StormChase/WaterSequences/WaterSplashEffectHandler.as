struct FStoneBeastChaseWaterSplashParams
{
	UPROPERTY()
	FVector Location;
	
	FStoneBeastChaseWaterSplashParams(FVector CurrentLocation)
	{
		Location = CurrentLocation;
	}
}

UCLASS(Abstract)
class UWaterSplashEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayersExitWater(FStoneBeastChaseWaterSplashParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastEnterWater(FStoneBeastChaseWaterSplashParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoneBeastExitWater(FStoneBeastChaseWaterSplashParams Params) {}

};