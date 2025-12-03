struct FTotemPuzzleEffectParams
{
	UPROPERTY()
	ETundraTotemIndex TotemIndex;

	FTotemPuzzleEffectParams(const ETundraTotemIndex InIndex)
	{
		TotemIndex = InIndex;
	}
}

class UTundra_River_TotemPuzzle_TreeControl_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TotemMovingUp(FTotemPuzzleEffectParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TotemMovingDown(FTotemPuzzleEffectParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TotemGroundSlammed(FTotemPuzzleEffectParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TriedToMoveTotemDownButIsAsLowAsItGoes(FTotemPuzzleEffectParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TriedToMoveTotemUpButIsAsHighAsItGoes(FTotemPuzzleEffectParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TriedToGroundSlamWhileTotemAtBottom(FTotemPuzzleEffectParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PuzzleSolved()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TriedWrongSolution()
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TotemReachedBottom(FTotemPuzzleEffectParams Params)
	{}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TotemStartShaking(FTotemPuzzleEffectParams Params)
	{}
};