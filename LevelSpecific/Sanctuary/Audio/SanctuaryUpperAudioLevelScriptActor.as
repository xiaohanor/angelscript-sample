class ASanctuaryUpperAudioLevelScriptActor : AHazeLevelScriptActor
{	
	UPROPERTY()
	TPerPlayer<bool> bHasOverlappedWith_Toturial_Land;
	UPROPERTY()
	TPerPlayer<bool> bHasOverlappedWith_Tutorial_Jump;

	UFUNCTION(BlueprintPure)
	bool HasOverlappedVolume(TPerPlayer<bool>& BoolArray, AHazePlayerCharacter Player)
	{
		return BoolArray[Player];
	}

	UFUNCTION()
	void SetOverlappedVolume(TPerPlayer<bool>& BoolArray, AHazePlayerCharacter Player)
	{
		BoolArray[Player] = true;
	}
}