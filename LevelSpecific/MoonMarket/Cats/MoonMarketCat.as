event void FOnMoonCatCollected(AHazePlayerCharacter Player);
event void FOnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat Cat);
event void FOnMoonCatStartDelivering(AHazePlayerCharacter Player);
event void FOnMoonCatFinishDelivering(AHazePlayerCharacter Player, AMoonMarketCat Cat);

class AMoonMarketCat : AHazeActor
{	
	//TODO depending on which version is approved, events will need some cleaning up
	UPROPERTY()
	FOnMoonCatSoulCaught OnMoonCatSoulCaught;

	UPROPERTY()
	FOnMoonCatStartDelivering OnMoonCatStartDelivering;

	UPROPERTY()
	FOnMoonCatFinishDelivering OnMoonCatFinishDelivering;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SkelRoot;

	UPROPERTY(DefaultComponent, Attach = SkelRoot, ShowOnActor)
	UHazeCharacterSkeletalMeshComponent SkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = SkelRoot)
	USphereComponent SoulCollision;
	default SoulCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
	default SoulCollision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);
	default SoulCollision.SetCollisionObjectType(ECollisionChannel::ECC_Visibility);

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.bIsImmediateTrigger = true;
	default InteractComp.MovementSettings.Type = EMoveToType::NoMovement;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent TrailEffect;
	default TrailEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent AmbientSpiritEffects;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent OffsetComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketCatSoulFollowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketCatSoulToGateCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 10000.0;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditAnywhere, Category = "Setup")
	EMoonMarketCatProgressionAreas CatType;

	UPROPERTY(EditAnywhere, Category = "Setup", EditInstanceOnly)
	bool bTriggerBoth = false;

	UPROPERTY(EditAnywhere, Category = "Setup", EditInstanceOnly)
	bool bDevFunctionDebug = false;

	UPROPERTY(EditAnywhere, EditInstanceOnly)
	float SoulCatchTime = 1.2;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect Rumble;

	UPROPERTY(EditAnywhere, EditInstanceOnly)
	bool bSaveCatOnCompletedOnly = false;

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = false;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem CatFoundSystem;

	//REMOVE LATER - REPLACE CUTSCENE CATS WITH ANIM CHARACTERS
	UPROPERTY(EditInstanceOnly)
	bool bCutsceneCat;

	UPROPERTY(EditAnywhere)	
	FAnimationMoonMarketCatAnimData Animations;

	UPROPERTY(EditAnywhere)
	FVector CatSoulFollowOffset;
	
	bool bHasbeenCompleted;

	AHazePlayerCharacter SoulTargetPlayer;

	UPROPERTY(EditInstanceOnly)
	AMoonGateCatHead CatHead;

	bool bFlyToCatHead;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		FHazeCameraWeightedFocusTargetInfo FocusTarget;
		FocusTarget.SetFocusToActor(this);
		InternalDisableCat(bStartDisabled);
	}

	FName GetCatName() const
	{
		switch(CatType)
		{
			case EMoonMarketCatProgressionAreas::GardenCat:
				return MoonMarketCatProgressionAreas::GardenCat;
			case EMoonMarketCatProgressionAreas::BabaYagaCat:
				return MoonMarketCatProgressionAreas::BabaYagaCat;
			case EMoonMarketCatProgressionAreas::GraveyardCat:
				return MoonMarketCatProgressionAreas::GraveyardCat;
			case EMoonMarketCatProgressionAreas::EntranceCat:
				return MoonMarketCatProgressionAreas::EntranceCat;
		}
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		InitiateCollectCatSoul(Player);
		InteractComp.Disable(this);
	}

#if EDITOR
	UFUNCTION(DevFunction)
	void DevIniditateCollectCatSoul()
	{
		SetActorLocation(Game::Zoe.ActorLocation);
		
		auto Comp = UMoonMarketPlayerSoulCollectComponent::Get(Game::Zoe);
		Comp.StartCatCollection(this);

		Timer::SetTimer(this, n"DevDelayedCatCollection", 0.1);
		
		OnMoonCatSoulCaught.Broadcast(Game::Zoe, this);	
		InteractComp.Disable(this);
	}
	
	UFUNCTION()
	void DevDelayedCatCollection()
	{
		FMoonMarketInteractingPlayerEventParams Params;
		Params.InteractingPlayer = Game::Zoe;
		UMoonMarketCatEventHandler::Trigger_OnCatStartCollecting(this, Params);
	}
#endif

	void InitiateCollectCatSoul(AHazePlayerCharacter Player, bool bPlayerInteracted = true)
	{
		if (bPlayerInteracted)
		{
			auto Comp = UMoonMarketPlayerSoulCollectComponent::Get(Player);
			Comp.StartCatCollection(this);
		}

		FMoonMarketInteractingPlayerEventParams Params;
		Params.InteractingPlayer = Player;
		UMoonMarketCatEventHandler::Trigger_OnCatStartCollecting(this, Params);
		
		OnMoonCatSoulCaught.Broadcast(Player, this);	
	}


	void CatchCatSoul(AHazePlayerCharacter Player)
	{
		SoulTargetPlayer = Player;
		FMoonMarketInteractingPlayerEventParams Params;
		Params.InteractingPlayer = Player;
		UMoonMarketCatEventHandler::Trigger_OnCatCollected(this, Params);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(CatFoundSystem, SkelMeshComp.GetBoundsOrigin());
		Player.PlayForceFeedback(Rumble, false, false, this);
	}

	void StartSoulDeliverance()
	{	
		UMoonMarketCatEventHandler::Trigger_OnStartFloatingToGate(this);
		bFlyToCatHead = true;
		OnMoonCatStartDelivering.Broadcast(SoulTargetPlayer);
	}

	void DeliverCatSoul()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(CatFoundSystem, SkelMeshComp.GetBoundsOrigin());
		UMoonMarketPlayerSoulCollectComponent::Get(SoulTargetPlayer).RemoveCat(this);
		SkelMeshComp.SetHiddenInGame(true);
		bHasbeenCompleted = true;
		CatHead.CatHeadActivated(SkelMeshComp.GetMaterial(0));
		OnMoonCatFinishDelivering.Broadcast(SoulTargetPlayer, this);
	}

	void SetCatCaughtState(AHazePlayerCharacter SavedPlayer)
	{
		ActorLocation = SavedPlayer.ActorLocation;
		SoulTargetPlayer = SavedPlayer;
		InteractComp.Disable(this);
		FMoonMarketInteractingPlayerEventParams Params;
		Params.InteractingPlayer = SoulTargetPlayer;
		UMoonMarketCatEventHandler::Trigger_OnCatCollected(this, Params);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(CatFoundSystem, SkelMeshComp.GetBoundsOrigin());
		InitiateCollectCatSoul(SavedPlayer, false);
	}

	void SetCatEndState()
	{
		CatHead.CatHeadActivated(SkelMeshComp.GetMaterial(0));
		OnMoonCatFinishDelivering.Broadcast(SoulTargetPlayer, this);
		AddActorDisable(this);
	}

	UFUNCTION()
	void InternalDisableCat(bool bSetIsDisabled)
	{
		if (bSetIsDisabled)
		{
			if (bDevFunctionDebug)
				Print("HWAT");

			AddActorDisable(this);
		}
		else
			RemoveActorDisable(this);
	}
};