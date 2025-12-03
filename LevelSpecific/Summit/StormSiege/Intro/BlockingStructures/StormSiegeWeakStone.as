class AStormSiegeWeakStone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ASummitNightQueenGem Gem;

	TArray<UStaticMeshComponent> MeshComps;

	bool bBroken;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);
		Gem.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		ActivateWeakStoneBreak();
	}

	UFUNCTION()
	void ActivateWeakStoneBreak()
	{
		if (bBroken)
			return;

		bBroken = true;
		
		for (UStaticMeshComponent Comp : MeshComps)
		{
			Comp.SetSimulatePhysics(true);
			FVector Dir = (Comp.WorldLocation - ActorLocation).GetSafeNormal();
			Comp.AddImpulse(Dir * 155000.0);
		}
	}
}