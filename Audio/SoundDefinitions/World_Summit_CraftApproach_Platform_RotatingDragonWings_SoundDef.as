
UCLASS(Abstract)
class UWorld_Summit_CraftApproach_Platform_RotatingDragonWings_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnDragonImpactSpinningBlocker(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable)
	UHazeAudioEmitter WingsMultiEmitter;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TArray<AActor> AttachedActors;
		HazeOwner.AttachParentActor.GetAttachedActors(AttachedActors);
		for(auto& Actor : AttachedActors)
		{
			AStaticMeshActor DragonWing = Cast<AStaticMeshActor>(Actor);
			if(DragonWing != nullptr)
			{
				//DragonWing.StaticMeshComponent.OnComponentHit.AddUFunction(this, n"OnDragonWingImpact");
			}
		}

		DefaultEmitter.SetEmitterLocation(HazeOwner.AttachParentActor.ActorLocation);
	}
}