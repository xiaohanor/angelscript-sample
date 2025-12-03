event void FOnSolarFlareSidescrollLiftCrash();

class ASolarFlareSidescrollLift : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareSidescrollLiftCrash OnSolarFlareSidescrollLiftCrash;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LiftRoot;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	UStaticMeshComponent DestroyedGlassMesh1;
	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	UStaticMeshComponent DestroyedGlassMesh2;
	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	UStaticMeshComponent DestroyedGlassMesh3;

	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	UNiagaraComponent Sparks1;
	default Sparks1.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	UNiagaraComponent Sparks2;
	default Sparks2.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	UNiagaraComponent Sparks3;
	default Sparks3.bAutoActivate = false;
	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	UNiagaraComponent Sparks4;
	default Sparks4.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = LiftRoot)
	UNiagaraComponent ImpactEffect;
	default ImpactEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USolarFlareSplineMoveComponent SplineMoveComp;
	default SplineMoveComp.bStartActive = false;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteraction;

	UPROPERTY(EditAnywhere)
	ASolarFlareWaveImpactEventActor EventActor;

	UPROPERTY(EditAnywhere)
	ADeathVolume BlockingDeathVolume;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor LiftCamera;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	ASolarFlareVOManager VOManager;

	bool bLiftActive = false;
	bool bLiftHasBroken;
	bool bLiftReachedEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VOManager = TListedActors<ASolarFlareVOManager>().GetSingle();
		EventActor.OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnSolarWaveImpactEventActorTriggered");
		SplineMoveComp.OnSolarFlareSplineMoveCompReachedEnd.AddUFunction(this, n"OnSolarFlareSplineMoveCompReachedEnd");
		DoubleInteraction.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		bLiftActive = true;
		DoubleInteraction.AddActorDisable(this);
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCamera(LiftCamera, 3.5, this); 
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		}

		BlockingDeathVolume.DisableDeathVolume(this);

		SplineMoveComp.ActivateSplineMovement();
		VOManager.TriggerSidescrollLiftStarted();

		FSolarFlareSidescrollLiftParams Params;
		Params.Location = ActorLocation;
		USolarFlareSidescrollLiftEffectHandler::Trigger_OnLiftStarted(this, Params);
	}

	UFUNCTION()
	private void OnSolarWaveImpactEventActorTriggered()
	{
		if (!bLiftActive)
			return;

		if (bLiftHasBroken)
			return;

		BP_LiftBreakage();
		SplineMoveComp.Speed = 2000.0;
		SplineMoveComp.InterpSpeed = 2500.0;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayCameraShake(CameraShake, this);
		}

		Sparks1.Activate();
		Sparks2.Activate();
		Sparks3.Activate();
		Sparks4.Activate();

		bLiftHasBroken = true;

		VOManager.TriggerSidescrollLiftImpact();

		FSolarFlareSidescrollLiftParams Params;
		Params.Location = ActorLocation;
		USolarFlareSidescrollLiftEffectHandler::Trigger_OnLiftFlareBreak(this, Params);
	}
	
	UFUNCTION()
	private void OnSolarFlareSplineMoveCompReachedEnd()
	{
		if (bLiftReachedEnd)
			return;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			Player.DeactivateCamera(LiftCamera, 2.5); 
		}

		Sparks1.Deactivate();
		Sparks2.Deactivate();
		Sparks3.Deactivate();
		Sparks4.Deactivate();

		ImpactEffect.Activate();

		DestroyedGlassMesh1.SetHiddenInGame(true);
		DestroyedGlassMesh2.SetHiddenInGame(true);
		DestroyedGlassMesh3.SetHiddenInGame(true);
		DestroyedGlassMesh1.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DestroyedGlassMesh2.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DestroyedGlassMesh3.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		FSolarFlareSidescrollLiftParams Params;
		Params.Location = ActorLocation;
		USolarFlareSidescrollLiftEffectHandler::Trigger_OnLiftCrash(this, Params);

		OnSolarFlareSidescrollLiftCrash.Broadcast();
	}

	//Sets end state on progress point
	UFUNCTION()
	void SetLiftEndState()
	{
		bLiftReachedEnd = true;

		DoubleInteraction.AddActorDisable(this);

		DestroyedGlassMesh1.SetHiddenInGame(true);
		DestroyedGlassMesh2.SetHiddenInGame(true);
		DestroyedGlassMesh3.SetHiddenInGame(true);
		DestroyedGlassMesh1.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DestroyedGlassMesh2.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DestroyedGlassMesh3.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		AddActorCollisionBlock(this);
		RemoveActorCollisionBlock(this);

		SplineMoveComp.SetToEndLocation();
		BP_LiftBreakageEndState();
	}

	UFUNCTION(BlueprintEvent)
	void BP_LiftBreakage() {}

	UFUNCTION(BlueprintEvent)
	void BP_LiftBreakageEndState() {}
};