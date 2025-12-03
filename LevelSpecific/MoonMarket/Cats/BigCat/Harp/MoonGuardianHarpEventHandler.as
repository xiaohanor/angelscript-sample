UCLASS(Abstract)
class UMoonGuardianHarpEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSuccessfulNote(FMoonMarketInteractingPlayerEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFailedNote(FMoonMarketInteractingPlayerEventParams Params)
	{
	}

};