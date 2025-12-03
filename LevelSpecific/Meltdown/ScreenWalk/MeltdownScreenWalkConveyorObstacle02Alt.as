class AMeltdownScreenWalkConveyorObstacle02Alt : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshTarget;
	default MeshTarget.SetHiddenInGame(true);
	default MeshTarget.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> ImpactShake;
	UPROPERTY(EditAnywhere)
	UNiagaraSystem ImpactEffect;
	UPROPERTY(EditAnywhere)
	UNiagaraSystem Explosion;
	
	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UBoxComponent Collision;

	UPROPERTY(EditAnywhere)
	bool bShouldTelegraph;

	UPROPERTY()
	bool bIsFalling;
	
	UPROPERTY(EditAnywhere)
	float Speed;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ImpactFF;

	FVector StartLocation;
	FVector EndLocation;

	UPROPERTY()
	float CurrentZ;

	UPROPERTY(DefaultComponent, Attach = MeshTarget)
	UTelegraphDecalComponent Telegraph;

	UPROPERTY()
	FonBoxDestroyed Boxdestoyed;

	UPROPERTY()
	FHazeTimeLike DropCubes;
	default DropCubes.Duration = 2.0;
	default DropCubes.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DropCubes.BindUpdate(this, n"CubeDropping");
		DropCubes.BindFinished(this, n"CubesDropped");

//		Collision.OnComponentBeginOverlap.AddUFunction(this, n"DamageOverlap");

		SetActorTickEnabled(false);

		StartLocation = ActorLocation;
		EndLocation = MeshTarget.WorldLocation;

	}

	// UFUNCTION()
	// private void DamageOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	//                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	//                            const FHitResult&in SweepResult)
	// {
	// 	AHazePlayerCharacter Player = Cast<AHazePlayerCharacter> (OtherActor);

	// 	if(bIsFalling && Player != nullptr)
	// 		Player.KillPlayer();
	
	// }

	UFUNCTION()
	void Start()
	{
		DropCubes.PlayFromStart();
		bIsFalling = true;
		if(bShouldTelegraph)
			Telegraph.ShowTelegraph();
			Telegraph.DetachFromParent(true);
	}

	UFUNCTION()
	private void CubesDropped()
	{
		SetActorTickEnabled(true);

		if(ImpactShake != nullptr)
			Game::Mio.PlayCameraShake(ImpactShake,this);

		if(ImpactFF != nullptr)
			Game::Mio.PlayForceFeedback(ImpactFF,false,false,this);
		
		if(bShouldTelegraph)
			UMeltdownScreenWalkConveyorMetalBoxEventHandler::Trigger_Impact(this);
	//	Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactEffect, MeshComp.WorldLocation, MeshComp.WorldRotation);

		bIsFalling = false;

		Telegraph.HideTelegraph();

		CurrentZ = MeshComp.RelativeLocation.Z;	
	}

	UFUNCTION()
	private void CubeDropping(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(StartLocation,EndLocation,CurrentValue));
	}

	UFUNCTION(BlueprintCallable)
	void CubeDropped()
	{
		UMeltdownScreenWalkConveyorMetalBoxEventHandler::Trigger_CollapseDropDownHit(this);
	}

	UFUNCTION(BlueprintEvent)
	void OnJumped()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		UMeltdownScreenWalkConveyorMetalBoxEventHandler::Trigger_Explosion(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Delta = -FVector::RightVector * Speed * DeltaSeconds;

		Debug::DrawDebugSphere(Collision.WorldLocation);

		AddActorLocalOffset(Delta);
		if(!bIsFalling)
			return;
		auto FallTrace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		FallTrace.UseBoxShape(Collision);
		FallTrace.IgnoreActor(this);
		FallTrace.DebugDrawOneFrame();
		auto Hits = FallTrace.QueryTraceMulti(Collision.WorldLocation, Collision.WorldLocation + Delta);
		for(auto Hit : Hits)
		{
			if(Hit.bBlockingHit)
			{
				if(Hit.Actor.IsA(AHazePlayerCharacter))
				{
					auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);

					if(!Player.IsPlayerDead())
						Player.KillPlayer();
				}
			}
		}
		

	}

};