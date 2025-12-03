UCLASS(Abstract)
class USanctuaryGrimbeastMortarPoolEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitPlayer(FSanctuaryGrimbeastMortarPoolOnHitPlayerEventData Data) {}
}

struct FSanctuaryGrimbeastMortarPoolOnHitPlayerEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FSanctuaryGrimbeastMortarPoolOnHitPlayerEventData(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
}