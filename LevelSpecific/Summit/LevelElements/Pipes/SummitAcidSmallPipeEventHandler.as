struct FSummitAcidPipePlayed
{
	UPROPERTY()
	int Index;

	FSummitAcidPipePlayed(int CurrentIndex)
	{
		Index = CurrentIndex;
	}
}

UCLASS(Abstract)
class USummitAcidSmallPipeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnNotePlayed(FSummitAcidPipePlayed Params) {}
};