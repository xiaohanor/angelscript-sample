
UCLASS(Abstract)
class UWorld_Island_Rift_Platform_FactorySmasher_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnHitConstraint(){}

	UFUNCTION(BlueprintEvent)
	void OnFullyUp(){}

	UFUNCTION(BlueprintEvent)
	void OnStartMovingDown(){}

	UFUNCTION(BlueprintEvent)
	void OnStartMovingUp(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditAnywhere)
	bool bUseLinkedZones = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (bUseLinkedZones)
			GetZoneOcclusionValue(DefaultEmitter,true,nullptr,true);
	}
}