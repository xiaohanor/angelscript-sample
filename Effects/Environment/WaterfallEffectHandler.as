struct FWaterfallPlayerEnterParams
{
	FWaterfallPlayerEnterParams(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}

	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FWaterfallPlayerExitParams
{
	FWaterfallPlayerExitParams(AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;
	}
	
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS()
class UWaterfallEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnterWaterfall(FWaterfallPlayerEnterParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLeaveWaterfall(FWaterfallPlayerExitParams Params)
	{
	}
};