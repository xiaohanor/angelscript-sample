struct FSolarFlareLiftActivatorParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USolarFlareLiftActivatorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLiftStarted(FSolarFlareLiftActivatorParams Params)
	{
	}
};