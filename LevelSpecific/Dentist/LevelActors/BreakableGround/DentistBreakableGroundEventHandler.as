struct FDentistBreakableGroundOnImpactEventData
{
	bool bIsHeadBonk = false;
};

UCLASS(Abstract)
class UDentistBreakableGroundEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistBreakableGround BreakableGround;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BreakableGround = Cast<ADentistBreakableGround>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FDentistBreakableGroundOnImpactEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBreak() {}
};