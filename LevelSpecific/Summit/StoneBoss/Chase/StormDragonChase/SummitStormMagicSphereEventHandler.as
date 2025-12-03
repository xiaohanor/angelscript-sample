struct FSummitMagicSphereImpact
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class USummitStormMagicSphereEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void MagicSphereImpact(FSummitMagicSphereImpact Impact) {}
}