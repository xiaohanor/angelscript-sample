event void FOnJunkPortalClosed();

class AMeltdownBossPhaseThreeJunkPortal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	UNiagaraSystem PortalSpawn;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;
	default PortalMesh.SetHiddenInGame(true);

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreeBouncingJunkAttack> JunkSpawn;

	UPROPERTY()
	FVector JunkSpawnLocation;
	
	UPROPERTY(DefaultComponent)
	UBillboardComponent SpawnBillboard;

	FHazeTimeLike PortalAnim;
	default PortalAnim.Duration = 1.0;
	default PortalAnim.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FOnJunkPortalClosed JunkPortalClosed;

	FVector StartScale;

	UPROPERTY()
	FVector EndScale;

	UPROPERTY()
	float SpawnDelay;

	FVector TargetLoc;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JunkSpawnLocation = SpawnBillboard.WorldLocation;

		Player = Game::GetClosestPlayer(ActorLocation);

		StartScale = PortalMesh.RelativeScale3D;

		SpawnDelay = Math::RandRange(0.2, 0.5);

		PortalAnim.BindFinished(this, n"OnPortalFinished");
		PortalAnim.BindUpdate(this, n"OnPortalUpdate");
	}

	UFUNCTION(BlueprintCallable)
	void StartPortal()
	{
		PortalMesh.SetHiddenInGame(false);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(PortalSpawn, ActorLocation);
		PortalAnim.Play();
	}

	UFUNCTION(BlueprintCallable)
	void StopPortal()
	{
		PortalAnim.Reverse();
	}

	UFUNCTION()
	private void OnPortalUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
	}

	UFUNCTION()
	private void OnPortalFinished()
	{
		if(PortalAnim.IsReversed())
		{
			PortalIsClosed();
			SetActorHiddenInGame(true);
			return;
		}

		SpawnDecimator();
		Timer::SetTimer(this, n"StopPortal", 1.0);
	}

	UFUNCTION(BlueprintEvent)
	void PortalIsClosed()
	{
		JunkPortalClosed.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void SpawnDecimator()
	{
		AMeltdownBossPhaseThreeBouncingJunkAttack OgreSpawned = Cast<AMeltdownBossPhaseThreeBouncingJunkAttack> (SpawnActor(JunkSpawn, JunkSpawnLocation, ActorRotation, bDeferredSpawn = true));
		FinishSpawningActor(OgreSpawned);
		OgreSpawned.Launch();
	}

	UFUNCTION(BlueprintCallable)
	void OrientToTarget()
	{
		TargetLoc = Player.ActorLocation;
		FVector Totarget = (TargetLoc - ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		FQuat TargetRot = Totarget.ToOrientationQuat();
		SetActorRotation(TargetRot);
	}
};