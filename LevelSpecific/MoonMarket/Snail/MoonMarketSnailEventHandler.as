struct FMoonMarketSnailPlayerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	FMoonMarketSnailPlayerParams(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;		
	}
}


UCLASS(Abstract)
class UMoonMarketSnailEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStartRide(FMoonMarketSnailPlayerParams Player) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStopRide(FMoonMarketSnailPlayerParams Player) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}
};