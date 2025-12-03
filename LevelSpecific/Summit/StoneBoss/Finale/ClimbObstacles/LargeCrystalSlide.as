class ALargeCrystalSlide : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	// UPROPERTY(DefaultComponent, Attach = MeshRoot)
	// UBoxComponent Collision;
	// default Collision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> PlatformsToDestroy;

	UPROPERTY(EditInstanceOnly)
	AStoneBeastCrystalJungleManager CrystalJungleManager;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	float ZStartOffset = -1000.0;
	float Speed = 1400.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshRoot.RelativeLocation = FVector(0,0,ZStartOffset);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, FVector(0), DeltaSeconds, Speed);
	}

	UFUNCTION()
	void ActivateLargeCrystalSlide()
	{
		SetActorTickEnabled(true);
		Game::Zoe.PlayCameraShake(CameraShake, this, 3);
		Timer::SetTimer(this, n"DelayedDestroyed", 0.4);
		ULargeCrystalSlideEffectHandler::Trigger_LargeCrystalRupture(this, FLargeCrystalRuptureParams(ActorLocation));
	}

	UFUNCTION()
	private void DelayedDestroyed()
	{
		for (AActor Actor : PlatformsToDestroy)
		{
			Actor.DestroyActor();
		}

		//TODO a break all functin instead maybe
		CrystalJungleManager.SetEndState();
		ULargeCrystalSlideEffectHandler::Trigger_DestroyCrystalRupturedObjects(this, FLargeCrystalRuptureParams(ActorLocation));
	}

	UFUNCTION()
	void SetLargeCrystalFinalState()
	{
		MeshRoot.RelativeLocation = FVector(0);

		for (AActor Actor : PlatformsToDestroy)
		{
			Actor.DestroyActor();
		}

		CrystalJungleManager.SetEndState();
	}
};