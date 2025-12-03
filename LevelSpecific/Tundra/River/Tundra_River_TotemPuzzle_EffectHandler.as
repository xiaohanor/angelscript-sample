UCLASS(Abstract)
class UTundra_River_TotemPuzzle_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MovingUp()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MovingDown()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GroundSlammed()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TriedToMoveDownButIsAsLowAsItGoes()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TriedToMoveUpButIsAsHighAsItGoes()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TriedToGroundSlamWhileAtBottom()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PuzzleSolved()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TriedWrongSolution()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TotemLocked()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CorrectTotemLocked()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TotemUnlocked()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TotemTargeted()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TotemUntargeted()
	{}
};