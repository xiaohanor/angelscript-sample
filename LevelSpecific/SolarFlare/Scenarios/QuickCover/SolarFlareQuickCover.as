class ASolarFlareQuickCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USolarFlareShieldMeshComponent ShieldMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent CoverBox;
	default CoverBox.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default CoverBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ShieldOn;
	default ShieldOn.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ShieldImpact;
	default ShieldImpact.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = CoverBox)
	USolarFlarePlayerCoverComponent CoverComp;
	default CoverComp.Distance = 600.0;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncFloatProgressMio;
	default SyncFloatProgressMio.SyncRate = EHazeCrumbSyncRate::PlayerSynced; 
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncFloatProgressZoe;
	default SyncFloatProgressZoe.SyncRate = EHazeCrumbSyncRate::PlayerSynced; 

	UPROPERTY(EditAnywhere)
	ASolarFlareWaveImpactEventActor Impact;

	UPROPERTY(EditAnywhere)
	TPerPlayer<AStaticCameraActor> CameraActor;

	UPROPERTY(EditAnywhere)
	ASolarFlareEnergyMechanism LeftEnergyMechanism;
	UPROPERTY(EditAnywhere)
	ASolarFlareEnergyMechanism RightEnergyMechanism;
	UPROPERTY(EditAnywhere)
	ASolarFlareBatteryShieldIndicator Indicator;
	UPROPERTY(EditAnywhere)
	bool bDebugPrint = false;
	UPROPERTY()
	UForceFeedbackEffect PowerRumble;
	UPROPERTY(EditDefaultsOnly)
	TPerPlayer<UAnimSequence> PlayerAnimations;

	UMaterialInstanceDynamic DynamicMat;

	// TPerPlayer<float> Progress;

	FVector StartLoc;
	float InitialTarget = 50.0;
	float MaxTarget = 250.0;
	float CurrentHeight;

	float InterpSpeed = 500.0;

	TPerPlayer<bool> bInUse;

	bool bShieldOn;
	bool bHasFlareImpact;
	float ImpactSafetyTime;
	float ImpactSafetyDuration = 0.25;
	float InteractionBrokenTime;
	bool bDisabledInteractions;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = MeshRoot.RelativeLocation;
		InteractionComp1.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionComp1.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		InteractionComp2.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionComp2.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");

		SyncFloatProgressMio.OverrideControlSide(Game::Mio);
		SyncFloatProgressZoe.OverrideControlSide(Game::Zoe);

		Impact.OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnSolarWaveImpactEventActorTriggered");
		CoverComp.AddDisabler(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (HasControl())
		{
			if (GetProgress() >= 0.96 && !bShieldOn)
			{
				NetShieldOn();
			}
			else if (GetProgress() < 0.96 && bShieldOn)
			{
				NetShieldOff();
			}
		}

		if (!bInUse[0] && !bInUse[1])
		{
			if (Game::Mio.HasControl())
			{
				SyncFloatProgressMio.Value -= DeltaSeconds;
				SyncFloatProgressMio.Value = Math::Clamp(SyncFloatProgressMio.Value, 0, 1);
			}
			
			if (Game::Zoe.HasControl())
			{
				SyncFloatProgressZoe.Value -= DeltaSeconds;
				SyncFloatProgressZoe.Value = Math::Clamp(SyncFloatProgressZoe.Value, 0, 1);
			}
		}

		LeftEnergyMechanism.UpdateTargetEnergy(SyncFloatProgressMio.Value * 2.0);
		RightEnergyMechanism.UpdateTargetEnergy(SyncFloatProgressZoe.Value * 2.0);

		if (bDisabledInteractions)
		{
			InteractionBrokenTime -= DeltaSeconds;

			if (InteractionBrokenTime <= 0.0)
			{
				InteractionComp1.Enable(this);
				InteractionComp2.Enable(this);
				bDisabledInteractions = false;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetShieldOn()
	{
		bShieldOn = true;
		ShieldMeshComp.TurnOn();
		ShieldMeshComp.SetRegenAlphaDirect(1.0);
		Indicator.TurnOn();
		CoverComp.RemoveDisabler(this);
		ShieldOn.Activate();
		CoverBox.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		FSolarFlareQuickCoverGeneralParams GeneralParams;
		GeneralParams.Location = ActorLocation;
		USolarFlareQuickCoverEffectHandler::Trigger_QuickCoverOn(this, GeneralParams);
		PlayShieldRumble();
	}

	UFUNCTION(NetFunction)
	void NetShieldOff()
	{
		bShieldOn = false;
		ShieldMeshComp.TurnOff();
		ShieldMeshComp.SetRegenAlphaDirect(0.0);
		Indicator.TurnOff();
		ShieldOn.Activate();

		if (!bHasFlareImpact)
		{
			CoverComp.AddDisabler(this);
			CoverBox.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

		FSolarFlareQuickCoverGeneralParams GeneralParams;
		GeneralParams.Location = ActorLocation;
		USolarFlareQuickCoverEffectHandler::Trigger_QuickCoverOff(this, GeneralParams);
		PlayShieldRumble();
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		auto UserComp = USolarFlarePlayerQuickCoverComponent::Get(Player);
		UserComp.StartQuickCover(InteractionComponent, this);
		bInUse[Player] = true;
		Player.ActivateCamera(CameraActor[Player], 2.0, this);
		FHazeSlotAnimSettings Settings;
		Settings.bLoop = true;
		Settings.BlendTime = 0.35;
		Player.PlaySlotAnimation(PlayerAnimations[Player], Settings);
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		auto UserComp = USolarFlarePlayerQuickCoverComponent::Get(Player);
		UserComp.StopQuickCover();
		bInUse[Player] = false;
		Player.DeactivateCamera(CameraActor[Player], 1.5);
		Player.StopAllSlotAnimations();
	}

	UFUNCTION()
	private void OnSolarWaveImpactEventActorTriggered()
	{
		if (bShieldOn)
		{
			ShieldMeshComp.RunImpact();
			ShieldImpact.Activate();
		}

		bShieldOn = false;
		bHasFlareImpact = true;
		
		InteractionComp1.KickAnyPlayerOutOfInteraction();
		InteractionComp2.KickAnyPlayerOutOfInteraction();

		Timer::SetTimer(this, n"DelayedRemoveSafetyAfterImpact", ImpactSafetyDuration);

		FSolarFlareQuickCoverGeneralParams GeneralParams;
		GeneralParams.Location = ActorLocation;
		USolarFlareQuickCoverEffectHandler::Trigger_QuickCoverImpact(this, GeneralParams);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto UserComp = USolarFlarePlayerQuickCoverComponent::Get(Player);
			UserComp.StopQuickCover();
			UpdateProgress(UserComp.InteractionSide, Player, 0.0);
			bInUse[Player] = false;
			Player.DeactivateCamera(CameraActor[Player], 1.5);
			InteractionBrokenTime = 1.0;
		}

		bDisabledInteractions = true;
		InteractionComp1.Disable(this);
		InteractionComp2.Disable(this);

	}

	UFUNCTION()
	void DelayedRemoveSafetyAfterImpact()
	{
		bHasFlareImpact = false;
		CoverComp.AddDisabler(this);
		CoverBox.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	void UpdateProgress(UInteractionComponent Interaction, AHazePlayerCharacter Player, float UpdatedProgress)
	{
		// Progress[Player] = UpdatedProgress;

		if (Player.IsMio())
			SyncFloatProgressMio.SetValue(UpdatedProgress);
		else	
			SyncFloatProgressZoe.SetValue(UpdatedProgress);
	}

	float GetProgress() const
	{
		return SyncFloatProgressMio.Value + SyncFloatProgressZoe.Value;
	}

	void PlayShieldRumble()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayForceFeedback(PowerRumble, false, true, this);
	}
};