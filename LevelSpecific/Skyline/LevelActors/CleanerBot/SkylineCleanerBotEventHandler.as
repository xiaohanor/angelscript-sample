struct FSkylineCleanerBotEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FSkylineCleanerBotEventData(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
}

UCLASS(Abstract)
class USkylineCleanerBotEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWeaponEngage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFireAtPlayer(FSkylineCleanerBotEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBlockedByPlayer() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChangeDirecton() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPerchStarted(FSkylineCleanerBotEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPerchStopped() {}
}