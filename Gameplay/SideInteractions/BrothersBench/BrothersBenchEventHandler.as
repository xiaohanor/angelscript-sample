struct FBrothersBenchOnPlayerSitDownEventData
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter Player;
};

struct FBrothersBenchOnPlayerGetUpEventData
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter Player;
};

struct FBrothersBenchOnConversationAbortedEventData
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter AbortedByPlayer;
}

UCLASS(Abstract)
class UBrothersBenchEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ABrothersBench BrothersBench;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BrothersBench = Cast<ABrothersBench>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerSitDown(FBrothersBenchOnPlayerSitDownEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerGetUp(FBrothersBenchOnPlayerGetUpEventData EventData) {}

	/**
	 * Both players have sit down and the camera move will now start
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConversationStarted() {}

	/**
	 * When one player gets up during/after the conversation
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnConversationAborted(FBrothersBenchOnConversationAbortedEventData EventData) {}
};