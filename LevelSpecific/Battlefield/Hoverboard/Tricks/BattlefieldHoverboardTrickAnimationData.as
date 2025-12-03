class UBattlefieldHoverboardTrickAnimationData : UDataAsset
{
	UPROPERTY()
	UAnimSequence Animation;

	UPROPERTY()
	FHazeRange FailWindow;

	UPROPERTY()
	float DurationBeforeTrickCompleted;
}