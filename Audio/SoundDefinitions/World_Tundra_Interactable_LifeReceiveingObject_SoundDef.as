
UCLASS(Abstract)
class UWorld_Tundra_Interactable_LifeReceiveingObject_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStopLifeGiving(FTundraLifeReceivingEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStartLifeGiving(FTundraLifeReceivingEffectParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	UTundraLifeReceivingComponent LifeComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		LifeComponent = UTundraLifeReceivingComponent::Get(HazeOwner);
	}

}