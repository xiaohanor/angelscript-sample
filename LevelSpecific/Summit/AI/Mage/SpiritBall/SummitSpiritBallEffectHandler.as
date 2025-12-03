struct FSummitSpiritBallParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USummitSpiritBallEffectHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MuzzleFlash(FSummitSpiritBallParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact(FSummitSpiritBallParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Shatter(FSummitSpiritBallParams Params) {}
}