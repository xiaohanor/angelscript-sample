UCLASS(Abstract)
class UTundra_River_TotemPuzzle_DisplayHeads_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HeadActivated()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HeadDeactivated()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PuzzleSolved()
	{}
};