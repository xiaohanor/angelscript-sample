event void FOnSummitStormMagicBarrierDestroyed();

class AMagicBarrier : AHazeActor
{
	UPROPERTY()
	FOnSummitStormMagicBarrierDestroyed OnMagicBarrierDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SphereComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(EditAnywhere)
	TArray<AStormKnight> StormKnights;

	UPROPERTY(EditAnywhere)
	TArray<AHazeProp> Props;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	int MaxKillCount;
	int KillCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AStormKnight Knight : StormKnights)
		{
			Knight.OnStormKnightDefeated.AddUFunction(this, n"OnStormKnightDefeated");
		}

		MaxKillCount = StormKnights.Num();
	}

	UFUNCTION()
	private void OnStormKnightDefeated()
	{
		KillCount++;

		if (KillCount == MaxKillCount)
		{
			DeactivateMagicBarrier();
		}
	}

	UFUNCTION()
	void DeactivateMagicBarrier()
	{
		MeshComp.SetHiddenInGame(true);
		OnMagicBarrierDestroyed.Broadcast();	
		SphereComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		for (AHazeProp Prop : Props)
		{
			Prop.DestroyActor();
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 10000.0, 40000.0);
		}
	}
}