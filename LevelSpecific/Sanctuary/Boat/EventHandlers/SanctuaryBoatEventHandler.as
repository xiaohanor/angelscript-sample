struct FSanctuaryBoatImpactEventData
{
	UPROPERTY()
	float ImpactStrength;
}

UCLASS(Abstract)
class USanctuaryBoatEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FSanctuaryBoatImpactEventData ImpactEventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Grabbed()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Released()
	{
	}
};