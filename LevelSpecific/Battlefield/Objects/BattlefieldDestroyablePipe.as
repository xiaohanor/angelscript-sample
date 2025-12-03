class ABattlefieldDestroyablePipe : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	UPROPERTY(DefaultComponent)
	UBattlefieldMissileResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnBattlefieldMissileImpact.AddUFunction(this, n"OnBattlefieldMissileImpact");
	}

	UFUNCTION()
	private void OnBattlefieldMissileImpact(FBattleFieldMissileImpactResponseParams Params)
	{
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		MeshComp.SetHiddenInGame(true);
	}
};