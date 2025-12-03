UCLASS(Abstract)
class USkylineTorSmashShockwaveEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShockwaveStart(FSkylineTorSmashShockwaveEventHandlerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShockwaveStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShockwaveStartFade(FSkylineTorSmashShockwaveEventHandlerData Data) {}
}

struct FSkylineTorSmashShockwaveEventHandlerData
{
	UPROPERTY()
	float Duration;

	FSkylineTorSmashShockwaveEventHandlerData(float _Duration)
	{
		Duration = _Duration;
	}
}