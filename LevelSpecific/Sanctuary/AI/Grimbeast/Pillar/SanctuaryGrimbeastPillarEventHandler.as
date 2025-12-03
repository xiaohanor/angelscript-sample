
struct FSanctuaryGrimbeastPillarEventParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USanctuaryGrimbeastPillarEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Anticipate(FSanctuaryGrimbeastPillarEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Erupt(FSanctuaryGrimbeastPillarEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Solidified(FSanctuaryGrimbeastPillarEventParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Demolished(FSanctuaryGrimbeastPillarEventParams Params)
	{
	}

};