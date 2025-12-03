class ULightSeekerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void FirstStartChasingLight() {}

	UFUNCTION(BlueprintEvent)
	void StartChasingLight() {}

	UFUNCTION(BlueprintEvent)
	void StopChasingLight() {}
}