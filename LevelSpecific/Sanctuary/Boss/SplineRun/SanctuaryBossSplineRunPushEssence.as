event void FBothPlayersInteractingPushEssenceSignature();

event void FBothPlayersCompletedSignature();

class ASanctuaryBossSplineRunPushEssence : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USanctuaryBossPushEssenceInteractionComponent MioInteract;

	UPROPERTY(DefaultComponent)
	USanctuaryBossPushEssenceInteractionComponent ZoeInteract;

	UPROPERTY(EditAnywhere)
	AInfuseEssenceBothManager EssenceManager;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossSplineRun MainSpline;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXFireComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem CompletionVFX;

	UPROPERTY(EditAnywhere)
	bool bIsLastEssence = false;

	UPROPERTY()
	FBothPlayersInteractingPushEssenceSignature OnBothPlayersInteracting;

	UPROPERTY()
	FBothPlayersCompletedSignature OnBothCompletedMash;


	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightEssencePivot;
	UPROPERTY(DefaultComponent, Attach = RightEssencePivot)
	UStaticMeshComponent RightEssenceHalf;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftEssencePivot;
	UPROPERTY(DefaultComponent, Attach = LeftEssencePivot)
	UStaticMeshComponent LeftEssenceHalf;



	UPROPERTY(EditAnywhere)
	FButtonMashSettings MashSettings;
	default MashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default MashSettings.bAllowPlayerCancel = false;
	

	UPROPERTY()
	UAnimSequence IdleAnim;
	UPROPERTY()
	UAnimSequence PushAnim;
	
	bool bCompleted = false;


	
	
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(EssenceManager!=nullptr)
		{
			EssenceManager.HideEssences();
			EssenceManager.AddActorDisable(this);
		}
		

		MioInteract.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");
		ZoeInteract.OnInteractionStarted.AddUFunction(this, n"HandleInteractionStarted");

	}
	
	UFUNCTION()
	private void HandleInteractionStarted(UInteractionComponent InteractionComponent,
	                                      AHazePlayerCharacter Player)
	{
		if (MioInteract.bInteracting && ZoeInteract.bInteracting)
		{
			OnBothPlayersInteracting.Broadcast();
		}

		if(!bIsLastEssence && MioInteract.bInteracting && ZoeInteract.bInteracting)
		{
			Game::Mio.BlockCapabilities(n"Death", Game::Mio);
			Game::Zoe.BlockCapabilities(n"Death", Game::Zoe);
			MainSpline.SetActorTickEnabled(false);
			MioInteract.bPlayerCanCancelInteraction = false;
			ZoeInteract.bPlayerCanCancelInteraction = false;
		}
			
	}

	UFUNCTION()
	private void HandleCompleted()
	{
		if(!bIsLastEssence)
		{
			MainSpline.SetActorTickEnabled(true);
			Game::Mio.UnblockCapabilities(n"Death", Game::Mio);
			Game::Zoe.UnblockCapabilities(n"Death", Game::Zoe);
		}
		
		VFXFireComp.Activate();
		MioInteract.KickAnyPlayerOutOfInteraction();
		ZoeInteract.KickAnyPlayerOutOfInteraction();

		MioInteract.Disable(this);
		ZoeInteract.Disable(this);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(CompletionVFX, VFXFireComp.GetWorldLocation());
		OnBothCompletedMash.Broadcast();

		if(EssenceManager!=nullptr)
		{
			EssenceManager.RespawnEssence();
			EssenceManager.RemoveActorDisable(this);
			Timer::SetTimer(this, n"ConsumeEssence", 1.0, false);
		}
		
		
	}

	

	UFUNCTION()
	private void ConsumeEssence()
	{
		EssenceManager.HandleInteractionStarted(EssenceManager.InteractComp, Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{


		RightEssencePivot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(35.0, 0.0, ZoeInteract.AccMashProgress.Value)));
		LeftEssencePivot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(-35.0, 0.0, MioInteract.AccMashProgress.Value)));

		MioInteract.SetRelativeLocation(FVector(0.0, Math::Lerp(-280.0, -200.0, MioInteract.AccMashProgress.Value), 0.0));
		ZoeInteract.SetRelativeLocation(FVector(0.0, Math::Lerp(280.0, 200.0, ZoeInteract.AccMashProgress.Value), 0.0));

		//PrintToScreen("Progress" + ZoeInteract.AccMashProgress.Value + MioInteract.AccMashProgress.Value);

		if(Math::IsNearlyEqual(ZoeInteract.MashProgress+ MioInteract.MashProgress, 2.0) && bCompleted==false)
		{
			bCompleted = true;
			HandleCompleted();
		}
	}

	UFUNCTION()
	void Break()
	{
	
		
		MioInteract.KickAnyPlayerOutOfInteraction();
		ZoeInteract.KickAnyPlayerOutOfInteraction();

		MioInteract.Disable(this);
		ZoeInteract.Disable(this);
	}
};