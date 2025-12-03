class ABattlefieldAutoCannon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent CannonMesh;

	UPROPERTY(DefaultComponent, Attach = CannonMesh)
	USceneComponent BarrelRotation;

	UPROPERTY(DefaultComponent, Attach = BarrelRotation)
	USceneComponent BarrelKickBack;

	UPROPERTY(DefaultComponent, Attach = BarrelKickBack)
	UStaticMeshComponent Barrels;

	UPROPERTY(DefaultComponent, Attach = BarrelKickBack)
	UNiagaraComponent MuzzleFlash1;
	default MuzzleFlash1.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = BarrelKickBack)
	UNiagaraComponent MuzzleFlash2;
	default MuzzleFlash2.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Barrels, ShowOnActor)
	UBattlefieldProjectileComponent ProjComp1;

	UPROPERTY(DefaultComponent, Attach = Barrels, ShowOnActor)
	UBattlefieldProjectileComponent ProjComp2;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;

	float KickBackAmount = 500.0;
	float CurrentKickBack;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProjComp1.OnBattlefieldProjectileFiredProjectile.AddUFunction(this, n"OnBattlefieldProjectileFiredProjectile");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentKickBack = Math::FInterpTo(CurrentKickBack, 0.0, DeltaSeconds, 3.0);
		BarrelKickBack.SetRelativeLocation(FVector(-CurrentKickBack, 0.0, 0.0));
	}

	UFUNCTION()
	private void OnBattlefieldProjectileFiredProjectile()
	{
		CurrentKickBack = KickBackAmount;
		UBattlefieldAutoCannonEventHandler::Trigger_OnShoot(this);
	}
};