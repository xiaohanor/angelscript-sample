class AGoldGiantStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(DefaultComponent)
	UGoldGiantBreakResponseComponent BreakComp;

	TArray<UStaticMeshComponent> MeshComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);
		BreakComp.OnBreakGiantObject.AddUFunction(this, n"OnGoldGiantBreak");
	}

	UFUNCTION()
	private void OnGoldGiantBreak(FVector ImpactDirection, float ImpulseAmount)
	{
		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetSimulatePhysics(true);
			FVector Impulse = ImpactDirection * ImpulseAmount;
			Mesh.AddImpulse(Impulse);
		}

		BoxComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		Timer::SetTimer(this, n"DeactivatePhysicsMeshes", 5.0, false);
	}

	UFUNCTION()
	void DeactivatePhysicsMeshes()
	{
		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetSimulatePhysics(false);
			Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			Mesh.SetHiddenInGame(true);
		}
	}
}