class ATundra_IcePalace_RangedShootProjectileCameraMover : AHazeActor
{
	AHazeLevelSequenceActor SphereProjectileSeqActor;
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION()
	void SphereProjectileSeqShouldFollowZoe(AHazeLevelSequenceActor SeqActor, bool bFollow)
	{
		SetActorTickEnabled(bFollow);
		SphereProjectileSeqActor = SeqActor;

		if(bFollow)
		{
			UTreeGuardianRangedShootHideOnCameraOverlapContainerComponent::GetOrCreate(Game::Zoe).HideOverlappedMeshes();
		}
		else
		{
			UTreeGuardianRangedShootHideOnCameraOverlapContainerComponent::GetOrCreate(Game::Zoe).ShowOverlappedMeshes();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SphereProjectileSeqActor == nullptr)
			return;

		SphereProjectileSeqActor.SetActorTransform(Game::Zoe.ActorTransform);
	}
};