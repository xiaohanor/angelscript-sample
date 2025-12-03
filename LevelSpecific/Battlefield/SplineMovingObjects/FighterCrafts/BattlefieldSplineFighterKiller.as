class ABattlefieldSplineFighterKiller : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBattlefieldProjectileComponent ProjComp1;
	default ProjComp1.bAutoBehaviour = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBattlefieldProjectileComponent ProjComp2;
	default ProjComp2.bAutoBehaviour = false;

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
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 8000.0, 18000.0, Scale = 0.5);
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
	private void OnBattlefieldReachedSplineEnd()
	{
		SetActorTickEnabled(false);
	}
}