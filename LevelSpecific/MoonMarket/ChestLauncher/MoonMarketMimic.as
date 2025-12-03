class AMoonMarketMimic : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh;
	default Mesh.ComponentTickEnabled = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;
	default InteractComp.bIsImmediateTrigger = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UOneShotInteractionComponent KickInteractComp;
	// default KickInteractComp.bShowCancelPrompt = false;
	// default KickInteractComp.bPlayerCanCancelInteraction = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent EntryCamera;
	AStaticCameraActor CameraStart;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"MimicChestReturnToStartCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MimicChestKickedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MimicChestCatCaughtCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MimicChestCatWaitingCapability");

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgressComp;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect KickRumble;

	UPROPERTY(EditAnywhere)
	float UpVelocity = 2000.0;

	UPROPERTY(EditAnywhere)
	float ForwardVelocity = 1500.0;

	UPROPERTY(EditInstanceOnly)
	bool bEatingACat = false;

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = false;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = "bEatingACat", EditConditionHides))
	AMoonMarketCat Cat;

	FVector StartLoc;
	FRotator StartRot;

	UPROPERTY()
	FHazePlaySlotAnimationParams KickAnimation;

	bool bFinishLaunch;
	bool bWasKicked;
	bool bCatCollected;
	bool bIsPlayerMimic = false;
	bool bEatingCatStarted = false;

	UPROPERTY(EditAnywhere)
	bool bDEBUGGING = false;

	UMoonMarketMimicPlayerComponent CurrentPlayer;

	bool bWasMioKicking;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bEatingACat)
		{
			KickInteractComp.OnInteractionStarted.AddUFunction(this, n"OnKicked");
			KickInteractComp.AddInteractionCondition(this, FInteractionCondition(this, n"CheckCanKick"));
			Cat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");
			Cat.InteractComp.Disable(this);
			Cat.AttachToComponent(Mesh, NAME_None, EAttachmentRule::KeepWorld);
			InteractComp.Disable(this);
		}
		else
		{
			KickInteractComp.Disable(this);
		}

		StartLoc = ActorLocation;
		StartRot = ActorRotation;
		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		CameraStart = SpawnActor(AStaticCameraActor, EntryCamera.WorldLocation, EntryCamera.WorldRotation);

		if (bStartDisabled)
			AddActorDisable(this);

		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}
	
	UFUNCTION()
	private EInteractionConditionResult CheckCanKick(const UInteractionComponent InInteractionComponent, AHazePlayerCharacter Player)
	{
		if(bCatCollected)
			return EInteractionConditionResult::Disabled;

		return EInteractionConditionResult::Enabled;
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		InteractComp.Disable(this);
	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat CurrentCat)
	{
		Cat.DetachFromActor(EDetachmentRule::KeepWorld);
		bCatCollected = true;
		YarnCatMimicVanish();
	}

	UFUNCTION()
	private void OnKicked(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		bWasKicked = true;
		UMoonMarketMimicEventHandler::Trigger_OnKicked(this, FMoonMarketInteractingPlayerEventParams(Player));
		bWasMioKicking = Player.IsMio();
		Timer::SetTimer(this, n"PlayKickAnim", 0.35);
	}

	UFUNCTION()
	void PlayKickAnim()
	{
		Mesh.PlaySlotAnimation(KickAnimation);
		if (bWasMioKicking)
			Game::Mio.PlayForceFeedback(KickRumble, false, false, this);
		else
			Game::Zoe.PlayForceFeedback(KickRumble, false, false, this);
	}

	UFUNCTION()
	private void DelayRumble()
	{
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		EatPlayer(Player);
	}

	void OnInteractionStopped()
	{
		if(CurrentPlayer != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CurrentPlayer.Owner);
			Player.DetachFromActor(EDetachmentRule::KeepWorld);
			auto LaunchComp = UMoonMarketMimicPlayerComponent::Get(Player);
			if(LaunchComp.bEaten)
			{
				Player.UnblockCapabilities(CapabilityTags::Movement, LaunchComp);
				Player.UnblockCapabilities(CapabilityTags::Visibility, LaunchComp);
				Player.DeactivateCameraByInstigator(LaunchComp, 3.0);
				Player.RemoveTutorialPromptByInstigator(LaunchComp);
			}

			CurrentPlayer.CurrentMimic = nullptr;
		}
	}

	void EatPlayer(AHazePlayerCharacter Player)
	{
		CurrentPlayer = UMoonMarketMimicPlayerComponent::Get(Player);
		CurrentPlayer.bEntering = true;
		CurrentPlayer.CurrentMimic = this;
		InteractComp.Disable(this);
		Player.ActivateCamera(CameraComp, 2.0, this);
		//Camera::BlendToFullScreenUsingProjectionOffset(Player, this, 2.0, 2.0);
	}

	void FinishLaunch()
	{
		bFinishLaunch = true;
	}

	void OnPlayerLaunched()
	{
		CurrentPlayer = nullptr;
	}

	void FinishReturnToStart()
	{
		InteractComp.Enable(this);
	}

	FVector GetLaunchVelocity()
	{
		FVector Velocity;
		Velocity += ActorForwardVector * ForwardVelocity;
		Velocity += ActorUpVector * UpVelocity;
		return Velocity;
	}

	UFUNCTION()
	void RemoveStartDisabled()
	{
		RemoveActorDisable(this);
	}

	void YarnCatMimicVanish()
	{
		// AppearEffect.Activate();
		// SetActorEnableCollision(false);
		// SetActorHiddenInGame(true);
		InteractComp.Disable(this);
	}

	UFUNCTION()
	void GraveyardMimicAppear()
	{
		RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_PlayMunchingTimeline() {}

	UFUNCTION(BlueprintEvent)
	void BP_PlayReadyTimeline() {}

	UFUNCTION(BlueprintEvent)
	void BP_PlayReleaseTimeline() {}

	UFUNCTION(BlueprintEvent)
	void BP_StopReadyTimeline() {}

	UFUNCTION(BlueprintCallable)
	void StartBounceAnimation()
	{
		bEatingCatStarted = true;
		Mesh.SetComponentTickEnabled(true);
	}
};