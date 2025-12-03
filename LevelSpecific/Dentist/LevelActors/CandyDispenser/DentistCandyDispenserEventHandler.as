struct FDentistCandyDispenserOnCandyDispensedEventData
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	FRotator Rotation;
};

UCLASS(Abstract)
class UDentistCandyDispenserEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistCandyDispenser CandyDispenser;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CandyDispenser = Cast<ADentistCandyDispenser>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCandyDispensed(FDentistCandyDispenserOnCandyDispensedEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingUp() {}
};