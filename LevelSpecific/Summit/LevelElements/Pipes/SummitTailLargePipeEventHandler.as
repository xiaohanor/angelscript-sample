struct FSummitTailPipePlayed
{
	UPROPERTY()
	int Index;

	FSummitTailPipePlayed(int CurrentIndex)
	{
		Index = CurrentIndex;
	}
}

UCLASS(Abstract)
class USummitTailLargePipeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnNotePlayed(FSummitTailPipePlayed Params) {}
};