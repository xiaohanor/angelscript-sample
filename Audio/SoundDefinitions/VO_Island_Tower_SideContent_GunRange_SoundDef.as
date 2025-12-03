
UCLASS(Abstract)
class UVO_Island_Tower_SideContent_GunRange_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnGunFireRangeActivated(FIslandGunRangeActivatedParams IslandGunRangeActivatedParams){}

	UFUNCTION(BlueprintEvent)
	void OnOneStar(){}

	UFUNCTION(BlueprintEvent)
	void OnTwoStars(){}

	UFUNCTION(BlueprintEvent)
	void OnThreeStars(){}

	UFUNCTION(BlueprintEvent)
	void OnCompleted(FIslandGunRangeScoreOnCompletedParams IslandGunRangeScoreOnCompletedParams){}

	/* END OF AUTO-GENERATED CODE */
	
	UPROPERTY(EditInstanceOnly)
	AIslandGunRangeScoreCount GunRangeScore;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger Trigger;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
	}

	UFUNCTION(BlueprintPure)
	bool IsSolo() const
	{
		for (auto Player: Game::Players)
		{
			if (!Trigger.IsPlayerInside(Player))
			{
				return true;
			}
		}

		return false;
	}
}