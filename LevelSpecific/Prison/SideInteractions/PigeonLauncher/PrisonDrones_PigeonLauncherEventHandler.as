UCLASS(Abstract)
class UPrisonDrones_PigeonLauncherEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APrisonDrones_PigeonLauncher Launcher;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Launcher = Cast<APrisonDrones_PigeonLauncher>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchPigeon()
	{
	}
};