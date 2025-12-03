struct FMoonMarketFlowerHatEffectParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	FVector Location;
	
	FMoonMarketFlowerHatEffectParams(AHazePlayerCharacter InPlayer, FVector InLocation)
	{
		Player = InPlayer;
		Location = InLocation;
	}
}

UCLASS(Abstract)
class UMoonMarketFlowerHatEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStartedAbility(FMoonMarketFlowerHatEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerStoppedAbility(FMoonMarketFlowerHatEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPickedUp(FMoonMarketFlowerHatEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlowersGrow(FMoonMarketFlowerHatEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlowersErase(FMoonMarketFlowerHatEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlowersWither(FMoonMarketFlowerHatEffectParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatDisintegrate(FMoonMarketFlowerHatEffectParams Params) {}
};