class ASummitTopDownBossGemPart : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MetalProtectorRotationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp; 
	default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = CapsuleComp)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;
	default TailResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeResponseComponent AdultTailResponseComp;
	default AdultTailResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent)
	USummitDestructibleResponseComponent DestroyableResponseComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int CrystalHealth = 3;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bInstantDestroyOnRollHit = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> CameraShake;
	
	bool bCrystalDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		TailResponseComp.OnHitByTailAttack.AddUFunction(this, n"OnHitByTailAttack");
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"RollHit");
		AdultTailResponseComp.OnHitBySmashMode.AddUFunction(this, n"OnSmashModeHit");
		DestroyableResponseComp.OnSummitDestructibleDestroyed.AddUFunction(this, n"OnSummitDestructibleDestroyed");
	}

	UFUNCTION()
	private void OnSummitDestructibleDestroyed()
	{
		CrumbDestroyCrystal();
	}

	UFUNCTION()
	private void OnHitByTailAttack(FTailAttackParams Params)
	{
		CrystalHealth--;

		if (CrystalHealth <= 0)
			CrumbDestroyCrystal();
	}

	UFUNCTION()
	private void RollHit(FRollParams Params)
	{
		if (bInstantDestroyOnRollHit)
			CrumbDestroyCrystal();
		else
			CrystalHealth--;
			
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSmashModeHit(FTailSmashModeHitParams Params)
	{
		CrystalHealth -= Math::FloorToInt(Params.DamageDealt);
		if(CrystalHealth <= 0)
			CrumbDestroyCrystal();
	}
	UFUNCTION(CrumbFunction)
	void CrumbDestroyCrystal()
	{
		if (bCrystalDestroyed)
			return;

		bCrystalDestroyed = true;

		Game::Mio.PlayCameraShake(CameraShake, this, 1.5, ECameraShakePlaySpace::World);
		Game::Zoe.PlayCameraShake(CameraShake, this, 1.5, ECameraShakePlaySpace::World);

		FSummitCrystalObeliskDestructionParams Params;
		Params.Location = ActorLocation;
		Params.Rotation = ActorRotation;
		USummitCrystalObeliskEffectsHandler::Trigger_DestroyCrystal(this, Params);

		AddActorDisable(this);
	}



}