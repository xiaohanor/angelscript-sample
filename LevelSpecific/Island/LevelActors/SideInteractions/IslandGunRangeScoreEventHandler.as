struct FIslandGunRangeScoreOnCompletedParams
{
	UPROPERTY()
	int StarAmount;
}

struct FIslandGunRangeActivatedParams
{
	// Will be nullptr if not instigated by player.
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UIslandGunRangeScoreEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGunFireRangeActivated(FIslandGunRangeActivatedParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOneStar()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTwoStars()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThreeStars()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompleted(FIslandGunRangeScoreOnCompletedParams Params)
	{
	}

};