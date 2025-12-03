event void FOnMoonMarketLanternLit();

class AMoonMarketBabaYagaLantern : AHazeActor
{
	UPROPERTY()
	FOnMoonMarketLanternLit OnMoonMarketLanternLit;


	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent LightComp;
	default LightComp.CastShadows = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LanternTurnOnEffect;
	default LanternTurnOnEffect.SetAutoActivate(false);

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	float LightIntensityTarget;
	float CurrentLightIntensity;

	UMaterialInstanceDynamic DynamicMat;
	float Blend = 1.0;

	bool bIsActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		LightIntensityTarget = LightComp.Intensity;
		CurrentLightIntensity = 0.0;
		LightComp.SetIntensity(0.15);
		DynamicMat = MeshComp.CreateDynamicMaterialInstance(0);

		if(DoubleInteract != nullptr)
		{
			DoubleInteract.OnPlayerStartedInteracting.AddUFunction(this, n"OnStartInteracting");
			DoubleInteract.OnPlayerStoppedInteracting.AddUFunction(this, n"OnStopInteracting");
			DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnCompleted");
		}
		else
		{
			PrintError("No double interaction has been assigned to " + ActorNameOrLabel);
		}
	}

	UFUNCTION()
	private void OnStartInteracting(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                                UInteractionComponent InteractionComponent)
	{
		UMoonMarketBabaYagaLanternEffectHandler::Trigger_OnInteractionStarted(this);

		if(Player.HasControl())
			UMoonMarketPlayerInteractionComponent::Get(Player).CrumbStopAllInteractions();
	}

	UFUNCTION()
	private void OnStopInteracting(AHazePlayerCharacter Player, ADoubleInteractionActor Interaction,
	                               UInteractionComponent InteractionComponent)
	{
		if(!bIsActivated)
			UMoonMarketBabaYagaLanternEffectHandler::Trigger_OnInteractionCanceled(this);
	}

	UFUNCTION()
	private void OnCompleted()
	{
		bIsActivated = true;
		UMoonMarketBabaYagaLanternEffectHandler::Trigger_OnLanternLit(this);
		SetActorTickEnabled(true);
		LanternTurnOnEffect.Activate();
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPolymorphResponseComponent::Get(Player).DesiredMorphClass = nullptr;
			Player.PlayForceFeedback(Rumble, false, false, this);
		}
	}

	void SetEndState()
	{
		SetActorTickEnabled(true);
		LanternTurnOnEffect.Activate();
		bIsActivated = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LightComp.SetIntensity(Math::FInterpConstantTo(LightComp.Intensity, LightIntensityTarget, DeltaSeconds, LightIntensityTarget));
		Blend = Math::FInterpConstantTo(Blend, 0.0, DeltaSeconds, 0.75);
		DynamicMat.SetScalarParameterValue(n"Blend", Blend);
	}

	void StartInteraction()
	{
	}

	void CancelInteraction()
	{
	}

	UFUNCTION()
	void ActivateLantern()
	{
		OnMoonMarketLanternLit.Broadcast();
	}
};