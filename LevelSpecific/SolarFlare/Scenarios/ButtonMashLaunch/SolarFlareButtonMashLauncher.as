event void FOnButtonMashBothStarted();
event void FOnButtonMashSucceeded();

class ASolarFlareButtonMashLauncher : AHazeActor
{
	UPROPERTY()
	FOnButtonMashBothStarted OnButtonMashBothStarted;

	UPROPERTY()
	FOnButtonMashSucceeded OnButtonMashSucceeded;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ChargeUpSystem;
	default ChargeUpSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent MuzzleFlashSystem;
	default MuzzleFlashSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent BodyRotation;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ClawRotation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LaunchReleaseSystem;
	default LaunchReleaseSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent LeftRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LaunchMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent RightRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent SteamSystem;
	default ChargeUpSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLight;
	default SpotLight.SetIntensity(5.0);
	default SpotLight.SetUseInverseSquaredFalloff(false);

	UPROPERTY(EditAnywhere)
	AStaticCameraActor Camera;

	UPROPERTY(EditAnywhere)
	FVector Impulse;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlareStabilizer> Stabilizers;	

	ASolarFlareSun Sun;

	FVector StartLoc;
	FVector EndLoc;
	float MaxPullback = 100.0;

	TPerPlayer<float> Progress;

	float TotalProgress;

	bool bLaunched;

	TPerPlayer<bool> bPlayersInteracting;

	bool bCompletedMash;

	float LightIntensity;
	float CurrentLightIntensity;
	FHazeAcceleratedFloat AcceleratedCurrentProgress;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChargeUpSystem.SetNiagaraVariableFloat("Alpha", 0.0);
		
		DoubleInteract.OnDoubleInteractionLockedIn.AddUFunction(this, n"OnDoubleInteractionLockedIn");
		DoubleInteract.OnPlayerStoppedInteracting.AddUFunction(this, n"OnPlayerStoppedInteracting");
		DoubleInteract.OnPlayerStartedInteracting.AddUFunction(this, n"OnPlayerStartedInteracting");

		DoubleInteract.PreventDoubleInteractionCompletion(this);

		StartLoc = ActorLocation;
		EndLoc = ActorLocation + (-LaunchMeshComp.UpVector * MaxPullback);

		LightIntensity = SpotLight.Intensity;

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Sun == nullptr)
			Sun = TListedActors<ASolarFlareSun>().GetSingle();

		FSolarFlareButtonMashLauncherPowerUpParams Params;
		Params.Location = ActorLocation;
		Params.Energy = GetFullProgress();
		USolarFlareButtonMashLauncherEffectHandler::Trigger_OnLauncherPoweringUpUpdated(this, Params);

		ChargeUpSystem.SetNiagaraVariableFloat("Alpha", GetFullProgress());

		for (ASolarFlareStabilizer Stabilizer : Stabilizers)
		{
			Stabilizer.UpdateChargeUpProgress(GetFullProgress());
		}

		Sun.UpdateAlpha(GetFullProgress());

		AcceleratedCurrentProgress.AccelerateTo(GetFullProgress(), 1.0, DeltaSeconds);

		CurrentLightIntensity = LightIntensity * GetFullProgress();
		SpotLight.SetIntensity(CurrentLightIntensity);
	}

	FVector GetLaunchLoc()
	{
		return StartLoc + (-LaunchMeshComp.UpVector * (MaxPullback * TotalProgress));
	}

	// UFUNCTION()
	// private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	//                                   AHazePlayerCharacter Player)
	// {
	// 	// Player.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
	// 	bPlayersInteracting[Player] = true;

	// 	USolarFlareTriggerShieldComponent Comp = USolarFlareTriggerShieldComponent::Get(Player);
	// 	Comp.SetShieldUnavailable(Player);

	// 	if (bPlayersInteracting[Player] && bPlayersInteracting[Player.OtherPlayer])
	// 	{
	// 		Player.ActivateCamera(Camera, 2.5, this);
	// 		Player.OtherPlayer.ActivateCamera(Camera, 2.5, this);
	// 		ChargeUpSystem.Activate();
			
	// 		for (ASolarFlareStabilizer Stabilizer : Stabilizers)
	// 			Stabilizer.ChargeUpSystem.Activate();
			
	// 		FSolarFlareButtonMashLauncherGeneralParams Params;
	// 		Params.Location = ActorLocation;
	// 		USolarFlareButtonMashLauncherEffectHandler::Trigger_OnLauncherPoweringUpStarted(this, Params);
	// 		SetActorTickEnabled(true);

	// 		bStartedInteraction = true;

	// 		OnButtonMashBothStarted.Broadcast();
	// 	}
	// }

	// UFUNCTION()
	// private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	//                                   AHazePlayerCharacter Player)
	// {
	// 	// Player.DeactivateCamera(Camera, 2.5);
	// 	bPlayersInteracting[Player] = false;

	// 	if (!bLaunched)
	// 	{
	// 		USolarFlareTriggerShieldComponent Comp = USolarFlareTriggerShieldComponent::Get(Player);
	// 		Comp.SetShieldAvailable(Player);
	// 	}
	// }

	UFUNCTION()
	private void OnDoubleInteractionLockedIn()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCamera(Camera, 2.5, this);
		}
		
		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);

		DoubleInteract.LeftInteraction.bPlayerCanCancelInteraction = false;
		DoubleInteract.RightInteraction.bPlayerCanCancelInteraction = false;

		Timer::SetTimer(this, n"DelayedLauncherActivate", 1.75);

		OnButtonMashBothStarted.Broadcast();
	}

	UFUNCTION()
	void DelayedLauncherActivate()
	{
		StartLaser();
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			USolarFlareButtonMashComponent::Get(Player).Launcher = this;
			USolarFlareButtonMashComponent::Get(Player).bCanButtonMash = true;
		}

		ChargeUpSystem.Activate();
		
		for (ASolarFlareStabilizer Stabilizer : Stabilizers)
			Stabilizer.ChargeUpSystem.Activate();

		FSolarFlareButtonMashLauncherGeneralParams Params;
		Params.Location = ActorLocation;
		USolarFlareButtonMashLauncherEffectHandler::Trigger_OnLauncherPoweringUpStarted(this, Params);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void OnPlayerStoppedInteracting(AHazePlayerCharacter Player,
	                                        ADoubleInteractionActor Interaction,
	                                        UInteractionComponent InteractionComponent)
	{
		USolarFlareTriggerShieldComponent Comp = USolarFlareTriggerShieldComponent::Get(Player);
		Comp.SetShieldAvailable(Player);
	}

	UFUNCTION()
	private void OnPlayerStartedInteracting(AHazePlayerCharacter Player,
	                                        ADoubleInteractionActor Interaction,
	                                        UInteractionComponent InteractionComponent)
	{
		USolarFlareTriggerShieldComponent Comp = USolarFlareTriggerShieldComponent::Get(Player);
		Comp.SetShieldUnavailable(Player);
	}

	void CompletedMash()
	{
		bLaunched = true;
		TotalProgress = 0.0;

		DoubleInteract.AllowDoubleInteractionCompletion(this);
		DoubleInteract.DisableDoubleInteraction(this);

		LaunchReleaseSystem.Activate();

		for (AHazePlayerCharacter Player : Game::Players)
		{
			USolarFlareTriggerShieldComponent Comp = USolarFlareTriggerShieldComponent::Get(Player);
			USolarFlareButtonMashComponent::Get(Player).bCanButtonMash = false;
			Comp.SetShieldUnavailable(Player);
			Comp.RemovePrompt(Player);
		}

		for (ASolarFlareStabilizer Stabilizer : Stabilizers)
		{
			Stabilizer.FinishSequence();
			Stabilizer.ChargeUpSystem.Deactivate();
		}

		SteamSystem.Activate();

		MuzzleFlashSystem.Activate();
		ChargeUpSystem.Deactivate();

		FSolarFlareButtonMashLauncherGeneralParams Params;
		Params.Location = ActorLocation;
		USolarFlareButtonMashLauncherEffectHandler::Trigger_OnLauncherCompleted(this, Params);
	}

	UFUNCTION()
	void SetProgressZero()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			UpdateProgress(Player, 0.0);
	}

	void UpdateProgress(AHazePlayerCharacter Player, float NewProgress)
	{
		Progress[Player] = NewProgress / 2;

		if (GetFullProgress() == 1.0)
		{
			if (HasControl() && !bCompletedMash)
			{
				bCompletedMash = true;
				CrumbCompleteInteraction(Player);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbCompleteInteraction(AHazePlayerCharacter Player)
	{
		CompletedMash();
		Player.BlockCapabilities(n"TriggerShield", this);
		Player.OtherPlayer.BlockCapabilities(n"TriggerShield", this);
		OnButtonMashSucceeded.Broadcast();
	}

	float GetFullProgress() const
	{
		return Progress[Game::Mio] + Progress[Game::Zoe];
	}

	UFUNCTION()
	void StartLaser()
	{
		BP_StartLaser();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartLaser() {}


	UFUNCTION()
	void ActivateBigLaser()
	{
		BP_BigBoomLaser();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BigBoomLaser() {}

	UFUNCTION()
	void DeactivateBigLaser()
	{
		SpotLight.SetIntensity(0.0);
		BP_DeactivateBigBoomLaser();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateBigBoomLaser() {}
};