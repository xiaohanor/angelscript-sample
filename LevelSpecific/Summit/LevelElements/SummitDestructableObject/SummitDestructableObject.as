class ASummitDestructableObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);


	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent  DestructionVFX;
	default DestructionVFX.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UAcidFruitResponseComponent ResponseComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnAcidFruitExplosion.AddUFunction(this, n"OnAcidFruitExplosion");
	}


	UFUNCTION()
	private void OnAcidFruitExplosion()
	{
		DestructionVFX.Activate();

		BoxComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		MeshComp.SetHiddenInGame(true);
	}
}