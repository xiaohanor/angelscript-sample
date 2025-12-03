struct FDentistDispensedCandyOnHitWaterEventData
{
	UPROPERTY()
	FVector Location;
};

UCLASS(Abstract)
class UDentistDispensedCandyEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistDispensedCandy DispenseCandy;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DispenseCandy = Cast<ADentistDispensedCandy>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitPlayer() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitWater(FDentistDispensedCandyOnHitWaterEventData EventData) {}
};