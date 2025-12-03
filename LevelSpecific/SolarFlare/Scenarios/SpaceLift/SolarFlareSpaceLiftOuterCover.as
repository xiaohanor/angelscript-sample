//Maybe replace with generic destructible actor?
class ASolarFlareSpaceLiftOuterCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USolarFlareCoverOverlapComponent CoverOverlapComp;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachComp;

	void ActivateDestruction()
	{
		Timer::SetTimer(this, n"DelayedRemoveCover", 0.5);
		TArray<UStaticMeshComponent> MeshComps;
		GetComponentsByClass(MeshComps);
		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetHiddenInGame(true);
			Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}

	UFUNCTION()
	void DelayedRemoveCover()
	{
		CoverOverlapComp.AddDisabler(this);
	}

	bool IsCoveringPlayer()
	{
		return CoverOverlapComp.IsCoveringPlayer();
	}
}