event void FOnSummitCrystalDestroyed(ASummitNightQueenGem CrystalDestroyed);

class USummitCrystalObeliskComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	FHazeShapeSettings MetalZoneShapeSetting;
}

class ASummitNightQueenGem : AHazeActor
{
	UPROPERTY()
	FOnSummitCrystalDestroyed OnSummitGemDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitNightQueenGem> LinkedGems;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	USummitCrystalObeliskComponent MetalControlZone;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MetalProtectorRotationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CrystalExplosionLocation;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UCapsuleComponent CapsuleComp; 
	default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, ShowOnActor)
	UTeenDragonTailAttackResponseComponent TailResponseComp;
	default TailResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UAdultDragonTailSmashModeResponseComponent AdultTailResponseComp;
	default AdultTailResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent)
	USummitDestructibleResponseComponent DestroyableResponseComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int CrystalHealth = 3;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bInstantDestroyOnRollHit = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bShouldBob;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DestructionEffectScale = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bIsRegularGem = true;

	FVector BobStartLocation;
	UPROPERTY(Category = "Settings", EditAnywhere, Meta = (EditCondition = "bShouldBob", EditConditionHides))
	float BobbingAmount = 50.0;
	UPROPERTY(Category = "Settings", EditAnywhere, Meta = (EditCondition = "bShouldBob", EditConditionHides))
	float BobbingSpeed = 1.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> CameraShake;
	
	bool bCrystalDestroyed = false;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ANightQueenMetal> PoweringMetalPieces; // For editor visualisation only!

	UPROPERTY(EditAnywhere, Category = Audio)
	UHazeAudioEvent SmashEvent = nullptr;

	UPROPERTY(EditAnywhere, Category = Audio, Meta = (ShowOnlyInnerProperties, EditCondition = "SmashEvent != nullptr"))
	FHazeAudioFireForgetEventParams AudioEventParams;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000;

	//EXTREMELY TEMP - DELETE LATER
	//This is for GemArenaTotem who inherits from this class - should be converted into an AI class later
	bool bPlayDefaultDestroyEffect = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		TailResponseComp.OnHitByTailAttack.AddUFunction(this, n"OnHitByTailAttack");
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"RollHit");
		AdultTailResponseComp.OnHitBySmashMode.AddUFunction(this, n"OnSmashModeHit");
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
	protected void OnSummitDestructibleDestroyed()
	{
		DestroyCrystal();			
	}

	UFUNCTION()
	protected void OnHitByTailAttack(FTailAttackParams Params)
	{
		CrystalHealth--;

		if (CrystalHealth <= 0)
			DestroyCrystal();
	}

	UFUNCTION()
	private void RollHit(FRollParams Params)
	{
		if (bInstantDestroyOnRollHit)
		{
			DestroyCrystal();
			Bp_TriggerRumble();

			for (ASummitNightQueenGem Gem : LinkedGems)
			{
				Gem.DestroyCrystal();
			}
		}
		else
			CrystalHealth--;
			
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSmashModeHit(FTailSmashModeHitParams Params)
	{
		CrystalHealth -= Math::FloorToInt(Params.DamageDealt);
		if(CrystalHealth <= 0)
			DestroyCrystal();
	}

	UFUNCTION()
	void DestroyCrystal()
	{
		if (bCrystalDestroyed)
			return;

		bCrystalDestroyed = true;

		if(!SceneView::IsFullScreen())
		{
			for (AHazePlayerCharacter Player : Game::Players)
				Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 2000.0, 5000.0, Scale = 1.5);
		}

		if (bPlayDefaultDestroyEffect)
		{
			FOnSummitGemDestroyedParams DestroyParams;
			DestroyParams.Location = CrystalExplosionLocation.WorldLocation;
			DestroyParams.Rotation = ActorRotation;
			DestroyParams.Scale = DestructionEffectScale;

			if (bIsRegularGem)
				USummitGemDestructionEffectHandler::Trigger_DestroyRegularGem(this, DestroyParams);
			else	
				USummitGemDestructionEffectHandler::Trigger_DestroySmallGem(this, DestroyParams);

			if(SmashEvent != nullptr)
			{
				AudioEventParams.Transform = Game::GetZoe().GetActorTransform();
				AudioComponent::PostFireForget(SmashEvent, AudioEventParams);
			}
		}
		
		OnSummitGemDestroyed.Broadcast(this);
		
		AddActorDisable(this);
	}

	UFUNCTION()
	void SetEndState()
	{
		bCrystalDestroyed = true;
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void Bp_TriggerRumble()
	{

	}

	UFUNCTION(CallInEditor, Category = "Regrowth")
	void AddMetalInZone()
	{
		TArray<ANightQueenMetal> MetalActorsInLevel = Editor::GetAllEditorWorldActorsOfClass(ANightQueenMetal);

		for(auto MetalActor : MetalActorsInLevel)
		{
			if(MetalControlZone.MetalZoneShapeSetting.IsPointInside(MetalControlZone.WorldTransform, MetalActor.ActorLocation))
			{
				auto Metal = Cast<ANightQueenMetal>(MetalActor);
				Metal.AddPoweringCrystal(this);
				PoweringMetalPieces.AddUnique(Metal);
			}
		}
	}

	// Sets the Powering Metal Pieces to the ones inside the zone
	UFUNCTION(CallInEditor, Category = "Regrowth")
	void SetMetalInZone()
	{
		TArray<ANightQueenMetal> MetalActorsInLevel = Editor::GetAllEditorWorldActorsOfClass(ANightQueenMetal);

		PoweringMetalPieces.Empty();
		for(auto MetalActor : MetalActorsInLevel)
		{
			if(MetalControlZone.MetalZoneShapeSetting.IsPointInside(MetalControlZone.WorldTransform, MetalActor.ActorLocation))
			{
				auto Metal = Cast<ANightQueenMetal>(MetalActor);
				Metal.AddPoweringCrystal(this);
				PoweringMetalPieces.AddUnique(Metal);
			}
		}
	}

	UFUNCTION(CallInEditor, Category = "Regrowth")
	void LinkupGems()
	{
	#if EDITOR
		// For syncing lists in crystal and metal in editor
		TArray<ANightQueenMetal> MetalActorsInLevel = Editor::GetAllEditorWorldActorsOfClass(ANightQueenMetal);

		for(auto MetalActor : MetalActorsInLevel)
		{
			auto Metal = Cast<ANightQueenMetal>(MetalActor);
			if(PoweringMetalPieces.Contains(Metal))
			{
				if(!Metal.PoweringCrystals.Contains(this))
				{
					Metal.AddPoweringCrystal(this);
				}
			}
			else
			{
				if(Metal.PoweringCrystals.Contains(this))
				{
					Metal.RemovePoweringCrystal(this);
				}
			}
		}

		// Remove duplicates of metal pieces when changing the reference
		for(int i = PoweringMetalPieces.Num() - 1; i >= 0; i--)
		{
			auto Metal = PoweringMetalPieces[i];

			if(Metal == nullptr)
				continue;

			for(int j = i - 1; j >= 0; j--)
			{
				auto OtherMetal = PoweringMetalPieces[j];

				if(OtherMetal == nullptr)
					continue;

				if(Metal == OtherMetal)
				{
					PoweringMetalPieces.RemoveSingleSwap(OtherMetal);
				}
			}
		}
	#endif
	}
}