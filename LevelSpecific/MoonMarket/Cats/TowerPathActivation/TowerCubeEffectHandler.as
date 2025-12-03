struct FTowerCubeParams
{
	UPROPERTY()
	FVector Location;
	FTowerCubeParams(FVector NewLocation)
	{
		Location = NewLocation;
	}
}

UCLASS(Abstract)
class UTowerCubeEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDefaultCubeDoubleInteractActivated(FTowerCubeParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCubeActivated(FTowerCubeParams Params) {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCubeDeactivate(FTowerCubeParams Params) {}
};