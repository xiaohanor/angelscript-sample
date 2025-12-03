
UCLASS(Abstract)
class UWorld_Skyline_Highway_Ambience_Spot_CablePanel_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	UGravityBladeCombatResponseComponent ResponseComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ResponseComponent = UGravityBladeCombatResponseComponent::Get(HazeOwner);
	}

}