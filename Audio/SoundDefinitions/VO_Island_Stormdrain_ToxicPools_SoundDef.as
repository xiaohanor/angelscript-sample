
UCLASS(Abstract)
class UVO_Island_Stormdrain_ToxicPools_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	TArray<AIslandStormdrainPerchableAcidBathDrone> PerchDrones;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TArray<AActor> OverlappingDrones;
		FHazeTraceSettings BoxTrace;
		BoxTrace.TraceWithObjectType(EObjectTypeQuery::WorldDynamic);
		APlayerVOTriggerVolume TriggerVolume = PlayerVOTriggerVolume::GetSoundDefVOTrigger(this);
		BoxTrace.UseBoxShape(TriggerVolume.BrushComponent.BoundsExtent);

		auto Overlaps = BoxTrace.QueryOverlaps(TriggerVolume.ActorLocation);
		for(auto& Overlap : Overlaps)
		{
			AIslandStormdrainPerchableAcidBathDrone PerchDrone = Cast<AIslandStormdrainPerchableAcidBathDrone>(Overlap.Actor);
			if(PerchDrone != nullptr)
			{
				PerchDrones.AddUnique(PerchDrone);
			}
		}
	}
}