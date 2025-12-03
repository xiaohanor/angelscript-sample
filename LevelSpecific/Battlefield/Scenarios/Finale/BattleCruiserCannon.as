class ABattleCruiserCannon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent RailGunEffect;
	default RailGunEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent MuzzleFlash;
	default MuzzleFlash.SetAutoActivate(false);
	
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"BattleCruiserEnterSideViewCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"BattleCruiserFireShellCapability");

	UPROPERTY(DefaultComponent)
	UBattlefieldHoverboardNoTurningSlopeComponent NoSlopeComp;

	UPROPERTY(EditAnywhere)
	TArray<ASplineActor> ShellSplines;

	UPROPERTY(EditAnywhere)
	ABothPlayerTrigger EnterCannonTrigger;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerEnterFiringRange;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> FireShellCameraShake;

	UPROPERTY(EditAnywhere)
	TArray<AHazeNiagaraActor> CannonFireNiagaraEffects;

	UPROPERTY(EditInstanceOnly)
	TArray<ABattleCruiserCannonChargeUpPiece> ChargeUpPieces;

	UPROPERTY()
	TSubclassOf<ABattleCruiserShell> ShellClass;

	int CurrentIndex;

	bool bFiringShells;
	bool bEnteredCannon;
	bool bEnteredFiringRange;

	float ActorOutAmount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChargeUpPieces = TListedActors<ABattleCruiserCannonChargeUpPiece>().GetArray();
	}

	void SpawnShellCasing()
	{
		ABattleCruiserShell NewShell = SpawnActor(ShellClass, ActorLocation, bDeferredSpawn = true);
		NewShell.SplineComp = ShellSplines[CurrentIndex].Spline;
		FinishSpawningActor(NewShell);

		CurrentIndex++;

		if (CurrentIndex > ShellSplines.Num() - 1)
			CurrentIndex = 0;
	}

	UFUNCTION()
	void ActivateCannon()
	{
		bFiringShells = true;
	}

	UFUNCTION()
	void DeactivateCannon()
	{
		bFiringShells = false;
	}

	UFUNCTION()
	void ShootCannon()
	{
		SpawnShellCasing();
		BP_CannonFired();
		RailGunEffect.Activate();
		MuzzleFlash.Activate();
		
		for (AHazeNiagaraActor Niagara : CannonFireNiagaraEffects)
		{
			Niagara.NiagaraComponent0.Activate();
		}

		for (ABattleCruiserCannonChargeUpPiece Piece : ChargeUpPieces)
		{
			Piece.Fire();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_CannonFired() {}
}