event void FOnSummitSiegeGemDestroyed(ASummitSiegeGem CrystalDestroyed);

class ASummitSiegeGem : AHazeActor
{
	UPROPERTY()
	FOnSummitSiegeGemDestroyed OnSummitGemDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitNightQueenGem> LinkedGems;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MetalProtectorRotationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UCapsuleComponent CapsuleComp; 
	default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UAdultDragonSpikeAutoAimComponent AutoAimCompTail;

	UPROPERTY(DefaultComponent)
	UAdultDragonTailSmashModeResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	USummitDestructibleResponseComponent DestroyableResponseComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int CrystalHealth = 1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bInstantDestroyOnRollHit = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DestructionEffectScale = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bShouldBob;
	UPROPERTY(Category = "Settings", EditAnywhere, Meta = (EditCondition = "bShouldBob", EditConditionHides))
	float BobbingAmount = 50.0;
	UPROPERTY(Category = "Settings", EditAnywhere, Meta = (EditCondition = "bShouldBob", EditConditionHides))
	float BobbingSpeed = 1.5;
	FVector BobStartLocation;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> CameraShake;
	
	bool bCrystalDestroyed = false;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ANightQueenMetal> PoweringMetalPieces; // For editor visualisation only!

	UPROPERTY(EditAnywhere, Category = Audio)
	UHazeAudioEvent SmashEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = Audio, Meta = (ShowOnlyInnerProperties, EditCondition = "SmashEvent != nullptr"))
	FHazeAudioFireForgetEventParams AudioEventParams;

	// UPROPERTY(DefaultComponent)
	// UDisableComponent DisableComp;
	// default DisableComp.bAutoDisable = true;
	// default DisableComp.bAutoActivate = true;
	// default DisableComp.AutoDisableRange = 150000;

	//EXTREMELY TEMP - DELETE LATER
	//This is for GemArenaTotem who inherits from this class - should be converted into an AI class later
	bool bPlayDefaultDestroyEffect = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		ResponseComp.OnHitBySmashMode.AddUFunction(this, n"OnHitBySmashMode");
		DestroyableResponseComp.OnSummitDestructibleDestroyed.AddUFunction(this, n"OnSummitDestructibleDestroyed");
		BobStartLocation = CapsuleComp.RelativeLocation;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bShouldBob)
			CapsuleComp.RelativeLocation = BobStartLocation + FVector(0.0, 0.0, BobbingAmount) * Math::Sin(Time::GameTimeSeconds * BobbingSpeed);
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
		{
			CrumbDestroyCrystal();

			for (ASummitNightQueenGem Gem : LinkedGems)
			{
				Gem.DestroyCrystal();
			}
		}
		else
			CrystalHealth--;
			
	}

	UFUNCTION()
	private void OnHitBySmashMode(FTailSmashModeHitParams Params)
	{
		CrystalHealth--;

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

		if (bPlayDefaultDestroyEffect)
		{
			FOnSummitGemDestroyedParams DestroyParams;
			DestroyParams.Location = ActorLocation;
			DestroyParams.Rotation = ActorRotation;
			DestroyParams.Scale = DestructionEffectScale;
			USummitGemDestructionEffectHandler::Trigger_DestroyRegularGem(this, DestroyParams);

			if(SmashEvent != nullptr)
			{
				AudioEventParams.Transform = Game::GetZoe().GetActorTransform();
				AudioComponent::PostFireForget(SmashEvent, AudioEventParams);
			}
		}
		OnSummitGemDestroyed.Broadcast(this);
		
		AddActorDisable(this);
	}
};