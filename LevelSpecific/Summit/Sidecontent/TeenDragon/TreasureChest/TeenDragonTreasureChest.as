class ATeenDragonTreasureChest : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TreasureChest;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CoinPile;
	default CoinPile.SetHiddenInGame(true);
	default	CoinPile.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UTeenDragonTailAttackResponseComponent ResponseComp;
	default ResponseComp.bShouldStopPlayer = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem FX_Burst;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		CoinPile.RelativeLocation = FVector(0,0,-150);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CoinPile.RelativeLocation = Math::VInterpTo(CoinPile.RelativeLocation, FVector(0), DeltaSeconds, 1.0);
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		TreasureChest.SetHiddenInGame(true);
		TreasureChest.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		CoinPile.SetHiddenInGame(false);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(FX_Burst, ActorLocation, ActorRotation);

		UTeenDragonTreasureChestEventHandler::Trigger_OnChestExplode(this);

		Game::Zoe.PlayCameraShake(CameraShake, this);
		Game::Zoe.PlayForceFeedback(Rumble, false, false, this);
		SetActorTickEnabled(true);
	}
};