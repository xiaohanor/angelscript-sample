event void FonBoxDestroyed();

class AMeltdownScreenWalkConveyorObstacle02Main : AHazeActor
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

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent Collision;

	UPROPERTY(EditAnywhere)
	float Speed;

	UPROPERTY(EditAnywhere)
	bool bShouldTelegraph;

	FVector StartLocation;
	FVector EndLocation;

	UPROPERTY()
	float CurrentZ;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ImpactFF;

	UPROPERTY(DefaultComponent, Attach = MeshTarget)
	UTelegraphDecalComponent  Telegraph;

	UPROPERTY()
	FonBoxDestroyed Boxdestoyed;

	UPROPERTY()
	FHazeTimeLike DropCubes;
	default DropCubes.Duration = 2.0;
	default DropCubes.UseLinearCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnJumpTrigger.AddUFunction(this, n"OnActivated");
		DropCubes.BindUpdate(this, n"CubeDropping");
		DropCubes.BindFinished(this, n"CubesDropped");

		SetActorTickEnabled(false);

		ResponseComp.OnStompedTrigger.AddUFunction(this, n"Stomping");

		Collision.OnComponentBeginOverlap.AddUFunction(this, n"DamageOverlap");

		StartLocation = ActorLocation;
		EndLocation = MeshTarget.WorldLocation;
	}


	UFUNCTION()
	private void Stomping()
	{
		UMeltdownScreenWalkConveyorWoodenBoxEventHandler::Trigger_Stomped(this, FMeltdownScreenWalkWoodenBox(MeshComp));
	}

	UFUNCTION()
	private void DamageOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter> (OtherActor);

		if(bShouldTelegraph && Player != nullptr)
			Player.KillPlayer();
	
	}

	UFUNCTION()
	void Start()
	{
		DropCubes.PlayFromStart();

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
		
		if(ImpactEffect != nullptr)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactEffect, MeshComp.WorldLocation, MeshComp.WorldRotation);
			UMeltdownScreenWalkConveyorWoodenBoxEventHandler::Trigger_Impact(this);
		}

		Telegraph.HideTelegraph();

		Collision.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		CurrentZ = ActorLocation.Z;	
	}

	UFUNCTION()
	private void CubeDropping(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(StartLocation,EndLocation,CurrentValue));
	}

	UFUNCTION(BlueprintCallable)
	void CubeDropped()
	{
		UMeltdownScreenWalkConveyorWoodenBoxEventHandler::Trigger_CollapseDropDownHit(this);
	}

	UFUNCTION()
	private void OnActivated()
	{
		OnJumped();
		Boxdestoyed.Broadcast();
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		UMeltdownScreenWalkConveyorWoodenBoxEventHandler::Trigger_Destroy(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalOffset(-FVector::RightVector * Speed * DeltaSeconds);
	}

	UFUNCTION(BlueprintEvent)
	void OnJumped()
	{

	}

};