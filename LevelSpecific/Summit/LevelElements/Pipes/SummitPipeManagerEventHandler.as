UCLASS(Abstract)
class USummitPipeManagerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPuzzleCompleted() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWrongAnswer() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRightAnswer() {}
};