struct FPhasableWallEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}


UCLASS(Abstract)
class UIslandPhasablePlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnParticlesBeginPhasing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnParticlesStopPhasing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerPhaseThrough(FPhasableWallEventData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerKilled(FPhasableWallEventData Params) {}
}