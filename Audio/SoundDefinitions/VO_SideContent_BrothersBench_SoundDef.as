
UCLASS(Abstract)
class UVO_SideContent_BrothersBench_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPlayerSitDown(FBrothersBenchOnPlayerSitDownEventData BrothersBenchOnPlayerSitDownEventData){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerGetUp(FBrothersBenchOnPlayerGetUpEventData BrothersBenchOnPlayerGetUpEventData){}

	UFUNCTION(BlueprintEvent)
	void OnConversationStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnConversationAborted(FBrothersBenchOnConversationAbortedEventData BrothersBenchOnConversationAbortedEventData){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditAnywhere)
	TArray<UHazeVoxAsset> DialogueList;

	UPROPERTY(EditAnywhere, Meta=(Units="sec"))
	float StartDelay;

	UPROPERTY(EditAnywhere, Meta=(Units="sec"))
	float DelayBetweenLines;

	UPROPERTY(EditAnywhere)
	UHazeVoxAsset MioAbortLine;

	UPROPERTY(EditAnywhere)
	UHazeVoxAsset ZoeAbortLine;

	UPROPERTY(EditAnywhere, Meta=(Units="sec"))
	float AbortedDelay;

	UPROPERTY()
	bool bHasAborted = false;

	UPROPERTY()
	bool bStartedAbort = false;

	int CurrentLineIndex = -1;

	UFUNCTION()
	void EvaluateNextLine() 
	{
		++CurrentLineIndex;

		if (!DialogueList.IsValidIndex(CurrentLineIndex))
			return;

		if (bHasAborted)
			return;
		
		OnContinueDialogue(DialogueList[CurrentLineIndex]);
	}

	UFUNCTION(BlueprintEvent)
	void OnContinueDialogue(UHazeVoxAsset NextLine) {}
}