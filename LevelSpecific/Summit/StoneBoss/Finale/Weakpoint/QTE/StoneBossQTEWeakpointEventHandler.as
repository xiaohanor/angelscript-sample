struct FStoneBossQTEWeakpointParams
{
	UPROPERTY()
	FVector MioSwordLocation;

	UPROPERTY()
	FVector ZoeSwordLocation;
}

UCLASS(Abstract)
class UStoneBossQTEWeakpointEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFirstStab(FStoneBossQTEWeakpointParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSecondStab(FStoneBossQTEWeakpointParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalStab(FStoneBossQTEWeakpointParams Params) {}
};