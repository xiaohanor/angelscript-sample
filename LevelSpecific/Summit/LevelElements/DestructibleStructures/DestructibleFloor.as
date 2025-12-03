class ADestructibleFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = BoxComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DestroySystem;
	default DestroySystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	USummitDestructibleResponseComponent ResponseComp;
	
	UPROPERTY(Category = "Setup")
	TSubclassOf<UCameraShakeBase> CameraShake; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnSummitDestructibleDestroyed.AddUFunction(this, n"OnSummitDestructibleDestroyed");
	}

	UFUNCTION()
	private void OnSummitDestructibleDestroyed()
	{
		DestroySystem.Activate();
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		MeshComp.SetHiddenInGame(true);
		BoxComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		Game::Mio.PlayCameraShake(CameraShake, this, 2.0);
		Game::Zoe.PlayCameraShake(CameraShake, this, 2.0);
	}
}