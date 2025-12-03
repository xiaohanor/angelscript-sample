class AGoatDevourDestructible : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DestructibleRoot;

	UPROPERTY(DefaultComponent, Attach = DestructibleRoot)
	UGoatDevourAutoAimTargetComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UGoatDevourSpitImpactResponseComponent SpitImpactResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpitImpactResponseComp.OnImpact.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(AHazeActor OwningActor, FHitResult HitResult)
	{
		BP_Impact();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Impact() {}
}