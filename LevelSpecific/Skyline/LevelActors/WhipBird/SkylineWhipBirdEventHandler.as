struct FSkylineBirdEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class USkylineWhipBirdEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWallImpact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGrabbed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnThrown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlyAway(FSkylineBirdEventData Data) {}
}