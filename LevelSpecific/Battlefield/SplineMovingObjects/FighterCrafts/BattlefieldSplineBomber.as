class ABattlefieldSplineBomber : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = Root)
	UBattlefieldMissileComponent MissileComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UBattlefieldSplineFollowComponent SplineFollowComp;
	default SplineFollowComp.bStartActive = false;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 12000.0, 20000.0, Scale = 0.5);
		}		
	}

	UFUNCTION()
	void StartSplineMovement()
	{
		SplineFollowComp.ActivateSplineMovement();
		SplineFollowComp.OnBattlefieldReachedSplineEnd.AddUFunction(this, n"OnBattlefieldReachedSplineEnd");
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void StartMissileAttack()
	{
		MissileComp.SpawnMissile();
	}

	UFUNCTION()
	void DestroyBomber()
	{
		FOnBattlefieldBomberDestroyedEffectParams EffectParams;
		EffectParams.Location = ActorLocation;
		UBattlefieldSplineBomberEffectHandler::Trigger_OnBomberDestroyed(this, EffectParams);
		SetActorHiddenInGame(false);
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnBattlefieldReachedSplineEnd()
	{
		SetActorTickEnabled(false);
	}
}