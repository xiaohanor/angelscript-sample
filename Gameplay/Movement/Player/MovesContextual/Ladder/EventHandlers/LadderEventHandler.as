
struct FLadderPlayerEventParams
{
	UPROPERTY()
	AHazePlayerCharacter Player = nullptr;

	FLadderPlayerEventParams(AHazePlayerCharacter _Player)
	{
		Player = _Player;
	}
}

class ULadderEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnteredMidAir(FLadderPlayerEventParams Params)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnteredFromWallRun(FLadderPlayerEventParams Params)
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnteredFromBottom(FLadderPlayerEventParams Params)
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerEnteredFromTop(FLadderPlayerEventParams Params)
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerExitedByCancelling(FLadderPlayerEventParams Params)
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerExitedByJumpingOut(FLadderPlayerEventParams Params)
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerExitedFromBottom(FLadderPlayerEventParams Params)
	{
		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerExitedFromTop(FLadderPlayerEventParams Params)
	{
		
	}

	//Yet to be implemented
	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void OnPlayerSteppedUp()
	// {
		
	// }

	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void OnPlayerSteppedDown()
	// {

	// }

	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void OnPlayerJumpedUp()
	// {

	// }

	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void OnPlayerStartedSlidingDown()
	// {

	// }

	// UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	// void OnPlayerStoppedSlidingDown()
	// {

	// }
}