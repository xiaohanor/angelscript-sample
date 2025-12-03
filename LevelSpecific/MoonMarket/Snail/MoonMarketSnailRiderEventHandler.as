struct FMoonMarketSnailEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	AMoonMarketSnail Snail;

	FMoonMarketSnailEventParams(AHazePlayerCharacter InPlayer, AMoonMarketSnail InSnail)
	{
		Player = InPlayer;
		Snail = InSnail;
	}
}

struct FMoonMarketSlipOnSlimeParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	FVector SlipLocation;

	FMoonMarketSlipOnSlimeParams(AHazePlayerCharacter InPlayer, FVector InLocation)
	{
		Player = InPlayer;
		SlipLocation = InLocation;
	}
}

UCLASS(Abstract)
class UMoonMarketSnailRiderEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRidingSnail(FMoonMarketSnailEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopRidingSnail(FMoonMarketSnailEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSlippedOnSlime(FMoonMarketSlipOnSlimeParams Params) {}
};