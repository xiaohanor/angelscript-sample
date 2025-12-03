struct FOverseerPOVEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

class UIslandOverseerPovEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReturnGrenadeHit(FOverseerPOVEventData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnVisorCrack() {}
}