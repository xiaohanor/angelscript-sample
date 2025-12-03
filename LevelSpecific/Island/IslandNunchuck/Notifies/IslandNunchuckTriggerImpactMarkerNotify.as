
/** This is just so we can get the time for triggering impacts */
class UIslandNunchuckTriggerImpactMarkerNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "IslandNunchuck_TriggerImpact";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		return true;
	}
}