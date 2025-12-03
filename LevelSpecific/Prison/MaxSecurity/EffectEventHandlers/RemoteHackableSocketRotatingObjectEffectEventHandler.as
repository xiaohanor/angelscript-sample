UCLASS(Abstract)
class URemoteHackableSocketRotatingObjectEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRotating() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRotating() {}
}