class ASkylineSentryBossMortar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent TelegraphMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UBoxComponent Collision;


	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireNiagara;

	UPROPERTY()
	UNiagaraSystem ExplosionNiagara;


	ASkylineSentryBossMortarArea MortarArea;

	UPROPERTY(EditAnywhere)
	float Speed = 2200;
	UPROPERTY(EditAnywhere)
	float TelegraphTime = 3;
	UPROPERTY(EditAnywhere)
	float TelegraphStartScale = 0.2;
	UPROPERTY(EditAnywhere)
	float TelegraphGrowSpeed = 3;
	float CurrentTelegraphScale;

	float FireLifeTime = 5;
	float TimeToRemoveFire;

	int Row;
	bool bMortarIsInMotion;
	bool bFireIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Root.SetHiddenInGame(true, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bFireIsActive)
		{
			if(TimeToRemoveFire < Time::GameTimeSeconds)
				FireNiagara.SetHiddenInGame(true, false);
		}


		if(!bMortarIsInMotion)
			return;


		MeshComp.WorldLocation -= ActorUpVector * Speed * DeltaSeconds;

		CurrentTelegraphScale += DeltaSeconds * TelegraphGrowSpeed;
		TelegraphMesh.SetRelativeScale3D(FVector(CurrentTelegraphScale, CurrentTelegraphScale, TelegraphMesh.WorldScale.Z));
		

		if(MeshComp.WorldLocation.Z > ActorLocation.Z)
			return;

		DeActivate();
	}


	UFUNCTION(BlueprintCallable)
	void Activate()
	{
		float Offset = Speed * TelegraphTime;
		MeshComp.WorldLocation = ActorLocation + ActorUpVector * Offset;

		CurrentTelegraphScale = TelegraphStartScale;
		TelegraphMesh.SetRelativeScale3D(FVector(CurrentTelegraphScale, CurrentTelegraphScale, TelegraphMesh.WorldScale.Z));

		MeshRoot.SetHiddenInGame(false, true);
		bMortarIsInMotion = true;
	}

	void DeActivate()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionNiagara, ActorLocation, ActorRotation);
		FireNiagara.SetHiddenInGame(false, false);
		bFireIsActive = true;
		TimeToRemoveFire = Time::GameTimeSeconds + FireLifeTime;

		MeshRoot.SetHiddenInGame(true, true);
		bMortarIsInMotion = false;
	}


};