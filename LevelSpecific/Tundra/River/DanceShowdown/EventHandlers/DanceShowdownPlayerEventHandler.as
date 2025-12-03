struct FDanceShowdownPlayerEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

class UDanceShowdownPlayerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMonkeyOnHead(FDanceShowdownPlayerEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMonkeyOnHead(FDanceShowdownPlayerEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTutorialPoseEntered() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCorrectPoseEntered(FDanceShowdownPoseData Pose) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSuccess(FDanceShowdownPlayerEventData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFail(FDanceShowdownPlayerEventData Data) {}
}