class ABreakableIndividualFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RiseEndPoint;

	UPROPERTY(DefaultComponent, Attach = RiseEndPoint)
	UBillboardComponent VisualEndPoint;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent NiagaraComp;
	default NiagaraComp.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	TArray<ASummitMagicWave> PassingMagicWaves;

	UPROPERTY(EditAnywhere)
	bool bDebug;

	FVector StartRelativeLoc;

	float LightningStartHeight = 5000.0;

	bool bGoingUp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRelativeLoc = MeshRoot.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bGoingUp)
		{
			MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, RiseEndPoint.RelativeLocation, DeltaSeconds, 500.0);

			if ((MeshRoot.RelativeLocation - RiseEndPoint.RelativeLocation).Size() < 0.2)
				bGoingUp = false;
		}
		else
		{
			MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, StartRelativeLoc, DeltaSeconds, 400.0);
		}
	}

	UFUNCTION()
	void ActivateFloorStrike()
	{
		float InnerDist = 1000.0;
		float OuterDist = 4000.0;
		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, InnerDist, OuterDist);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, InnerDist, OuterDist);

		// NiagaraComp.Activate();
		bGoingUp = true;
		// MeshComp.SetHiddenInGame(true);
		// MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}
}