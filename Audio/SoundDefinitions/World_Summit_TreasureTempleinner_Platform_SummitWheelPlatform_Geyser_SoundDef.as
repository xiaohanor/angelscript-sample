
UCLASS(Abstract)
class UWorld_Summit_TreasureTempleinner_Platform_SummitWheelPlatform_Geyser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnFinishedErupting(){}

	UFUNCTION(BlueprintEvent)
	void OnStartedErupting(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerLaunched(FSummitGeyserOnPlayerLaunchedParams Params){}

	/* END OF AUTO-GENERATED CODE */

	// Works just like a gate, but if we require a something more complex it easy to modify.
	int32 PlayersCount = 0;

	UFUNCTION(BlueprintPure)
	bool HasLaunchedPlayers()
	{
		return PlayersCount > 0;
	}

	UFUNCTION(BlueprintCallable)
	void AddPlayerLaunched(AHazePlayerCharacter Player)
	{
		++PlayersCount;
	}

	UFUNCTION(BlueprintCallable)
	void ResetPlayersLaunched()
	{
		PlayersCount = 0;
	}
}