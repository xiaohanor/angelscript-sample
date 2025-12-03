struct FSolarFlareButtonMashLauncherGeneralParams
{
	UPROPERTY()
	FVector Location;
}

struct FSolarFlareButtonMashLauncherPowerUpParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	float Energy;
}

UCLASS(Abstract)
class USolarFlareButtonMashLauncherEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLauncherPoweringUpStarted(FSolarFlareButtonMashLauncherGeneralParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLauncherPoweringUpUpdated(FSolarFlareButtonMashLauncherPowerUpParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLauncherCompleted(FSolarFlareButtonMashLauncherGeneralParams Params) {}

};