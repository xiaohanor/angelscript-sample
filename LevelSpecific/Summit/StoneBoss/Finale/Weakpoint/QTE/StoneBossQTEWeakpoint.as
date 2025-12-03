asset StoneBossQTEWeakpointPlayerSheet of UHazeCapabilitySheet
{
	Components.Add(UStoneBossQTEWeakpointPlayerComponent);
	AddCapability(n"StoneBossQTEWeakpointPlayerCapability");
	AddCapability(n"StoneBossQTEWeakpointSwordDrawBackCapability");
	AddCapability(n"StoneBossQTEWeakpointSwordReleaseCapability");
	AddCapability(n"StoneBossQTEWeakpointSwordHitSuccessCapability");
	AddCapability(n"StoneBossQTEWeakpointSwordHitFailCapability");
	AddCapability(n"StoneBossQTEWeakpointSwordSyncCapability");
}

asset StoneBossQTEWeakpointButtonMashSheet of UHazeCapabilitySheet
{
	// AddCapability(n"StoneBossQTEWeakpointButtonMashCapability");
	Components.Add(UStoneBossQTEWeakpointButtonMashComponent);
}

event void FOnStoneBossWeakpointDamaged(float HealthPercentage);
event void FOnStoneBossWeakpointDestroyed();
event void FOnStoneBossWeakpointActivated();
event void FOnStoneBossWeakpointDeactivated();
event void FOnStoneBossWeakpointSuccessfulHit();
event void FOnStoneBossWeakpointUnsuccessfulHit(FStoneBossWeakpointUnsuccessfulHitParams Params);
event void FOnStoneBossWeakpointOnFirstMashCompletedEvent();
event void FOnStoneBossWeakpointOnSecondMashCompletedEvent();
event void FOnStoneBossWeakpointHealthDepletedEvent();

enum EStoneBossQTENetHitSyncInfo
{
	NotSet,
	Success,
	Fail
}

struct FStoneBossWeakpointUnsuccessfulHitParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FStoneBossWeakpointSuccessfulHitParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

class AStoneBossQTEWeakpoint : AHazeActor
{
	UPROPERTY()
	FOnStoneBossWeakpointDestroyed OnStoneBossWeakpointDestroyed;

	UPROPERTY()
	FOnStoneBossWeakpointActivated OnStoneBossWeakpointActivated;

	// Always fires when either ejected or destroyed
	UPROPERTY()
	FOnStoneBossWeakpointDeactivated OnStoneBossWeakpointDeactivated;

	UPROPERTY()
	FOnStoneBossWeakpointSuccessfulHit OnStoneBossWeakpointSuccessfulHit;

	UPROPERTY()
	FOnStoneBossWeakpointUnsuccessfulHit OnStoneBossWeakpointUnsuccessfulHit;

	UPROPERTY()
	FOnStoneBossWeakpointHealthDepletedEvent OnStoneBossWeakpointHealthDepleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CoreMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BrokenCoreMesh;
	default BrokenCoreMesh.SetHiddenInGame(true);
	default BrokenCoreMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UNetworkLockComponent NetworkLock;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	USceneComponent CombinedSwordRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent ZoeSwordRoot;

	UPROPERTY(DefaultComponent, Attach = ZoeSwordRoot)
	UStaticMeshComponent ZoeSwordMeshComp;
	default ZoeSwordMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = ZoeSwordMeshComp)
	UStaticMeshComponent PrototypeCombinedSword;
	default PrototypeCombinedSword.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = ZoeSwordRoot)
	USceneComponent ZoeSwordDrawnBackRoot;

	UPROPERTY(DefaultComponent, Attach = ZoeSwordRoot)
	USceneComponent ZoeSwordHitRoot;

	UPROPERTY(DefaultComponent, Attach = ZoeSwordRoot)
	USceneComponent ZoeSwordHitDrawBackRoot;

	UPROPERTY(DefaultComponent, Attach = ZoeSwordRoot)
	USceneComponent ZoeSwordSuccessfulHitRoot;

	UPROPERTY(DefaultComponent, Attach = ZoeSwordRoot)
	USceneComponent ZoeSwordFailedHitRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent MioSwordRoot;

	UPROPERTY(DefaultComponent, Attach = MioSwordRoot)
	USceneComponent MioSwordDrawnBackRoot;

	UPROPERTY(DefaultComponent, Attach = MioSwordRoot)
	USceneComponent MioSwordHitRoot;

	UPROPERTY(DefaultComponent, Attach = MioSwordRoot)
	USceneComponent MioSwordHitDrawBackRoot;

	UPROPERTY(DefaultComponent, Attach = MioSwordRoot)
	USceneComponent MioSwordSuccessfulHitRoot;

	UPROPERTY(DefaultComponent, Attach = MioSwordRoot)
	USceneComponent MioSwordFailedHitRoot;

	UPROPERTY(DefaultComponent, Attach = MioSwordRoot)
	UStaticMeshComponent MioSwordMeshComp;
	default MioSwordMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UInteractionComponent MioInteract;
	default MioInteract.bPlayerCanCancelInteraction = false;

	UPROPERTY(DefaultComponent)
	UInteractionComponent ZoeInteract;
	default ZoeInteract.bPlayerCanCancelInteraction = false;

	UPROPERTY(DefaultComponent)
	USceneComponent MioFinalStabLocationComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ZoeFinalStabLocationComp;

	UPROPERTY(DefaultComponent)
	USceneComponent FocusCameraRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(StoneBossQTEWeakpointButtonMashSheet);

	UPROPERTY(EditAnywhere, Category = "Setup")
	UStaticMesh SwordMesh;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem FailedHitSparkEffect;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<UCameraShakeBase> FailedHitCameraShake;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<UCameraShakeBase> SuccessfulHitCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UForceFeedbackEffect ImpactRumble;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bStartInvincible = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float CameraActivationBlendTime = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int StartHealth = 1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartInteractionsDisabled = true;

	UPROPERTY(EditAnywhere, Category = "Sword Settings")
	float SwordDrawBackDuration = 1.3;

	UPROPERTY(EditAnywhere, Category = "Sword Settings")
	float SwordReleaseDuration = 3.0;

	UPROPERTY(EditAnywhere, Category = "Sword Settings")
	float SwordHitDuration = 0.4;

	UPROPERTY(EditAnywhere, Category = "Sword Settings")
	float SwordHitDrawBackDuration = 0.65;

	UPROPERTY(EditAnywhere, Category = "Sword Settings")
	float SwordSucceedHitDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Sword Settings")
	float SwordFailHitDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Sword Settings")
	float SwordSucceedTimerThreshold = 0.5;

	UPROPERTY(EditAnywhere, Category = "Camera")
	UHazeCameraSettingsDataAsset DrawBackCameraSettings;

	UPROPERTY(EditAnywhere, Category = "Camera")
	float DrawBackCameraSettingsBlendInTime = 2.5;

	UPROPERTY(EditAnywhere, Category = "Camera")
	UHazeCameraSettingsDataAsset ReleaseCameraSettings;

	UPROPERTY(EditAnywhere, Category = "Camera")
	float ReleaseCameraSettingsBlendInTime = 1.5;

	int CurrentHealth;

	FVector ZoeSwordRootLoc;
	FVector MioSwordRootLoc;

	private bool bCombinedSwordMode;
	bool bInvincible;

	TOptional<bool> StabIsSuccessful;
	TPerPlayer<bool> bPlayerIsInteracting;

	UPROPERTY(NotVisible, BlueprintHidden)
	AFocusCameraActor FocusCamera;

	bool bHasFocusedSwordsWithCamera = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bActivateMashOnHealthDepleted = false;

	// UPROPERTY(EditAnywhere, Category = "Settings|ButtonMash")
	// AFocusCameraActor FirstButtonMashFocusCamera;
	// UPROPERTY(EditAnywhere, Category = "Settings|ButtonMash")
	// float FirstButtonMashBlendInTime = 1;
	// UPROPERTY(EditAnywhere, Category = "Settings|ButtonMash")
	// AFocusCameraActor SecondButtonMashFocusCamera;
	// UPROPERTY(EditAnywhere, Category = "Settings|ButtonMash")
	// float SecondButtonMashBlendInTime = 1;

	UPROPERTY(EditAnywhere, Category = "Settings|ButtonMash")
	AStaticCameraActor ButtonMashFocusCamera;
	float ButtonMashBlendInTime = 1;

	UPROPERTY()
	FOnStoneBossWeakpointOnFirstMashCompletedEvent OnFirstButtonMashCompleted;
	UPROPERTY()
	FOnStoneBossWeakpointOnSecondMashCompletedEvent OnSecondButtonMashCompleted;

	default ActorTickEnabled = false;

	UStoneBossQTEWeakpointPlayerComponent ZoeWeakpointComp;
	UStoneBossQTEWeakpointPlayerComponent MioWeakpointComp;
	UStoneBossQTEWeakpointButtonMashComponent StoneBossButtonMashComp;

	TPerPlayer<bool> PlayersActivelySyncing;
	private TPerPlayer<bool> PlayersReadyToStab;

	float TimeWhenBothPlayersWereReadyToStab;

	bool bHasSyncedHit;
	EStoneBossQTENetHitSyncInfo HitSyncInfo;

	TPerPlayer<bool> PlayersHitSyncFinished;

	FInstigator CurrentButtonMashInstigator;

	float TimeToRegisterStabHit = 0.4;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bInvincible = bStartInvincible;

		MioInteract.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		MioInteract.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");

		ZoeInteract.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		ZoeInteract.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");

		ZoeWeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Game::Zoe);
		MioWeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Game::Mio);
		StoneBossButtonMashComp = UStoneBossQTEWeakpointButtonMashComponent::Get(this);

		if (bStartInteractionsDisabled)
		{
			ZoeInteract.Disable(this);
			MioInteract.Disable(this);
		}

		CurrentHealth = StartHealth;

		PrototypeCombinedSword.SetHiddenInGame(true);

		ZoeSwordMeshComp.SetVisibility(false);
		MioSwordMeshComp.SetVisibility(false);

		ZoeSwordRootLoc = ZoeSwordRoot.RelativeLocation;
		MioSwordRootLoc = MioSwordRoot.RelativeLocation;

		if (FocusCamera == nullptr)
			SpawnFocusCamera();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		FTemporalLog Log = TEMPORAL_LOG(this);
		Log.Value("MioSync", PlayersActivelySyncing[Game::Mio]);
		Log.Value("MioHitSyncFinished", PlayersHitSyncFinished[Game::Mio]);
		Log.Value("ZoeSync", PlayersActivelySyncing[Game::Zoe]);
		Log.Value("ZoeHitSyncFinished", PlayersHitSyncFinished[Game::Zoe]);
		Log.Value("HitSyncInfo", HitSyncInfo);
		Log.Value("bHasSyncedHit", bHasSyncedHit);
#endif
	}

#if EDITOR
	UFUNCTION(DevFunction)
	private void AddActionForBothPlayers(FName ActionName, EStoneBossQTEPlayerTestActionType ActionType = EStoneBossQTEPlayerTestActionType::Hold, float MioHoldDuration = 0, float ZoeHoldDuration = 0)
	{
		FName Action = ActionName;
		if (ActionName == "")
			Action = StoneBossQTEWeakpoint::TestPrimaryAction;
		UStoneBossQTEPlayerTestInputComponent::Get(Game::Mio).AddAction(Action, ActionType, MioHoldDuration);
		UStoneBossQTEPlayerTestInputComponent::Get(Game::Zoe).AddAction(Action, ActionType, ZoeHoldDuration);
	}
#endif

	bool AreBothPlayersSyncing()
	{
		return PlayersActivelySyncing[Game::Mio] && PlayersActivelySyncing[Game::Zoe];
	}

	UFUNCTION(NetFunction)
	void NetSetHitInfo(EStoneBossQTENetHitSyncInfo HitInfo)
	{
		if (HitSyncInfo != EStoneBossQTENetHitSyncInfo::NotSet)
			return;

		HitSyncInfo = HitInfo;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetSyncComplete()
	{
		bHasSyncedHit = true;
	}

	void ClearSync()
	{
		HitSyncInfo = EStoneBossQTENetHitSyncInfo::NotSet;
		bHasSyncedHit = false;
	}

	bool AreBothPlayersReadyToStab()
	{
		return PlayersReadyToStab[Game::Mio] && PlayersReadyToStab[Game::Zoe];
	}

	void SetPlayerReadyToStab(AHazePlayerCharacter Player)
	{
		PlayersReadyToStab[Player] = true;
		if (AreBothPlayersReadyToStab())
			TimeWhenBothPlayersWereReadyToStab = Time::GameTimeSeconds;
	}

	void ClearPlayerReadyToStab(AHazePlayerCharacter Player)
	{
		PlayersReadyToStab[Player] = false;
	}

	UFUNCTION()
	void EnableInteractions()
	{
		ZoeInteract.Enable(this);
		MioInteract.Enable(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void InteractionStarted(UInteractionComponent InteractionComponent,
							AHazePlayerCharacter Player)
	{
		ZoeWeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Game::Zoe);
		MioWeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(Game::Mio);
		bPlayerIsInteracting[Player] = true;
		auto PlayerComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player);
		PlayerComp.SetActiveWeakpoint(this);

		Player.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);

		if (bPlayerIsInteracting[Player] && bPlayerIsInteracting[Player.OtherPlayer])
			InteractCompleted();

		Player.HealPlayerHealth(100.0);
	}

	UFUNCTION(NotBlueprintCallable)
	private void InteractionStopped(UInteractionComponent InteractionComponent,
							AHazePlayerCharacter Player)
	{
		if (Player.AttachParentActor == this)
			Player.DetachFromActor(EDetachmentRule::KeepWorld);
		bPlayerIsInteracting[Player] = false;

		Player.DeactivateCamera(FocusCamera, CameraActivationBlendTime);

		if (HasBeenDestroyed())
		{
			Timer::SetTimer(this, n"OnTimerTimeout", 3);
			return;
		}

		auto PlayerComp = UStoneBossQTEWeakpointPlayerComponent::Get(Player);
		PlayerComp.Weakpoint = nullptr;

		if (bPlayerIsInteracting[Player] || bPlayerIsInteracting[Player.OtherPlayer])
		{
			Game::Zoe.DeactivateCamera(FocusCamera, CameraActivationBlendTime);
		}

		InteractionComponent.Enable(this);
		ClearPlayerInteraction(Player);
	}

	UFUNCTION()
	private void OnTimerTimeout()
	{
		ZoeWeakpointComp.Weakpoint = nullptr;
		MioWeakpointComp.Weakpoint = nullptr;
	}

	void InteractCompleted()
	{
		if (!bHasFocusedSwordsWithCamera)
		{
			for (auto Player : Game::Players)
			{
				auto SwordComp = UDragonSwordUserComponent::Get(Player);
				auto Sword = SwordComp.Weapon;

				FHazeCameraWeightedFocusTargetInfo SwordFocusInfo;
				SwordFocusInfo.SetFocusToActor(Sword);
				FocusCamera.FocusTargetComponent.AddFocusTarget(SwordFocusInfo, this);
				bHasFocusedSwordsWithCamera = true;
			}
		}

		Game::Zoe.ActivateCamera(FocusCamera, CameraActivationBlendTime, this, EHazeCameraPriority::High);

		MioInteract.Disable(this);
		ZoeInteract.Disable(this);

		OnStoneBossWeakpointActivated.Broadcast();
	}

	UFUNCTION()
	void ManualInteractionComplete()
	{
		InteractCompleted();
	}

	UFUNCTION(DevFunction)
	void GetHit()
	{
		CurrentHealth--;
		if (HasControl())
			CrumbGetHit(CurrentHealth);
	}

	UFUNCTION(CrumbFunction)
	void CrumbGetHit(int NewHealth)
	{
		bool bIsFinalWeakpoint = bActivateMashOnHealthDepleted;
		FStoneBossQTEWeakpointParams Params;
		Params.ZoeSwordLocation = ZoeFinalStabLocationComp.WorldLocation;
		Params.MioSwordLocation = MioFinalStabLocationComp.WorldLocation;
		if (NewHealth <= 0)
		{
			if (bIsFinalWeakpoint)
				CrumbSetWeakpointInfo(EPlayerStoneBossQTEFinalWeakpointStateInfo::ButtonMashStab);

			OnStoneBossWeakpointHealthDepleted.Broadcast();
			UStoneBossQTEWeakpointEventHandler::Trigger_OnSecondStab(this, Params);
		}
		else
		{
			UStoneBossQTEWeakpointEventHandler::Trigger_OnFirstStab(this, Params);
		}

		OnStoneBossWeakpointSuccessfulHit.Broadcast();
	}

	void FailedHit(AHazePlayerCharacter Player)
	{
		FStoneBossWeakpointUnsuccessfulHitParams Params;
		Params.Player = Player;
		OnStoneBossWeakpointUnsuccessfulHit.Broadcast(Params);
	}

	// Force eject manually
	UFUNCTION()
	void ForceEjectPlayers()
	{
		for (auto Player : Game::Players)
			ClearPlayerInteraction(Player);

		ZoeSwordMeshComp.SetVisibility(false);
		MioSwordMeshComp.SetVisibility(false);

		OnStoneBossWeakpointDeactivated.Broadcast();

		MioInteract.Enable(this);
		ZoeInteract.Enable(this);

		for (AHazePlayerCharacter Player : Game::Players)
			bPlayerIsInteracting[Player] = false;
	}

	UFUNCTION()
	void ClearPlayerHoldAnims()
	{
		if (HasControl())
			CrumbClearPlayerHoldAnims();
	}

	UFUNCTION(CrumbFunction)
	void CrumbClearPlayerHoldAnims()
	{
		ZoeWeakpointComp.ClearHoldSuccessAnim();
		MioWeakpointComp.ClearHoldSuccessAnim();
	}

	private void FinalHit()
	{
		if (!bActivateMashOnHealthDepleted)
		{
			// Locks players in for a time before weakpoint gets destroyed
			for (auto Player : Game::Players)
			{
				if (Player.AttachParentActor == this)
					Player.DetachFromActor(EDetachmentRule::KeepWorld);

				ClearPlayerInteraction(Player);
			}

			BrokenCoreMesh.SetHiddenInGame(false);
			CoreMesh.SetHiddenInGame(true);

			MioInteract.Disable(this);
			ZoeInteract.Disable(this);

			for (AHazePlayerCharacter Player : Game::Players)
				bPlayerIsInteracting[Player] = false;

			OnStoneBossWeakpointDeactivated.Broadcast();
			OnStoneBossWeakpointDestroyed.Broadcast();
		}
	}

	UFUNCTION()
	void DestroyWeakpoint()
	{
		FinalHit();
	}

	void ClearPlayerInteraction(AHazePlayerCharacter Player)
	{
		Player.RemoveTutorialPromptByInstigator(this);

		if (Player.IsMio())
			MioInteract.KickAnyPlayerOutOfInteraction();
		else
			ZoeInteract.KickAnyPlayerOutOfInteraction();
	}

	// Called in blueprint after cutscene for final combined sword moment
	UFUNCTION()
	void SetInvincibilityMode(bool bInvincibility)
	{
		bInvincible = bInvincibility;
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void SpawnFocusCamera()
	{
		if (FocusCamera != nullptr)
			return;

		FocusCamera = AFocusCameraActor::Spawn(FocusCameraRoot.WorldLocation, FocusCameraRoot.WorldRotation);
		FocusCamera.AttachToComponent(FocusCameraRoot);
	}

	bool HasBeenDestroyed() const
	{
		return CurrentHealth <= 0.0;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetWeakpointInfo(EPlayerStoneBossQTEFinalWeakpointStateInfo StateInfo)
	{
		StoneBossButtonMashComp.FinalWeakpointActiveStateInfo = StateInfo;
	}

	UFUNCTION()
	void ActivateFirstButtonMash()
	{
		StoneBossButtonMashComp.ActivateFirstButtonMash();
		for (auto Player : Game::Players)
		{
			auto SwordComp = UDragonSwordUserComponent::Get(Player);
			FStoneBeastWeakpointFirstMashStartedParams Params;
			Params.Player = Player;
			Params.SwordLocation = SwordComp.Weapon.ActorLocation;
			UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnFinalWeakpointFirstMashStarted(Player, Params);
		}
	}

	UFUNCTION()
	void ActivateSecondButtonMash()
	{
		StoneBossButtonMashComp.ActivateSecondButtonMash();
		for (auto Player : Game::Players)
		{
			auto SwordComp = UDragonSwordUserComponent::Get(Player);
			FStoneBeastWeakpointSecondMashStartedParams Params;
			Params.Player = Player;
			Params.SwordLocation = SwordComp.Weapon.ActorLocation;
			UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnFinalWeakpointSecondMashStarted(Player, Params);
		}
		// UStoneBossQTEWeakpointEffectHandler::Trigger_OnFinalWeakpointButtonMash2Started(this);
	}

	UFUNCTION(DevFunction)
	void CompleteFirstMash()
	{
		OnFirstButtonMashCompleted.Broadcast();
		for (auto Player : Game::Players)
		{
			auto SwordComp = UDragonSwordUserComponent::Get(Player);
			FStoneBeastWeakpointFirstMashCompletedParams Params;
			Params.Player = Player;
			Params.SwordLocation = SwordComp.Weapon.ActorLocation;
			UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnFinalWeakpointFirstMashCompleted(Player, Params);
		}
		// UStoneBossQTEWeakpointEffectHandler::Trigger_OnFinalWeakpointButtonMash1Completed(this);
	}

	UFUNCTION(DevFunction)
	void CompleteSecondMash()
	{
		OnSecondButtonMashCompleted.Broadcast();

		for (auto Player : Game::Players)
		{
			auto SwordComp = UDragonSwordUserComponent::Get(Player);
			FStoneBeastWeakpointSecondMashCompletedParams Params;
			Params.Player = Player;
			Params.SwordLocation = SwordComp.Weapon.ActorLocation;
			UStoneBossQTEWeakpointPlayerEffectHandler::Trigger_OnFinalWeakpointSecondMashCompleted(Player, Params);
		}

		FStoneBossQTEWeakpointParams Params;
		Params.ZoeSwordLocation = ZoeFinalStabLocationComp.WorldLocation;
		Params.MioSwordLocation = MioFinalStabLocationComp.WorldLocation;
		UStoneBossQTEWeakpointEventHandler::Trigger_OnFinalStab(this, Params);
		// UStoneBossQTEWeakpointEffectHandler::Trigger_OnFinalWeakpointButtonMash2Completed(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ShowAuraFX() {}

	UFUNCTION()
	void ActivateAuraEffect()
	{
		BP_ShowAuraFX();
	}
};