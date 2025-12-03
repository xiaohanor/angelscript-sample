struct FDarkCaveBellParams
{
	UPROPERTY()
	FVector Location;

	FDarkCaveBellParams(FVector NewLoc)
	{
		Location = NewLoc;
	}
}

UCLASS(Abstract)
class USummitDarkCaveBellEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBellRing(FDarkCaveBellParams Params)
	{
	}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBellImpactByRoll()
	{
	}
};