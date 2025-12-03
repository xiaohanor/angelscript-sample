UCLASS(Abstract)
class UTundra_River_InteractableCasinoEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStartCasino() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWinConditionStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMidConditionStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLoseConditionStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStartedRoulette() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerWinRoulette() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLoseRoulette() {}

}