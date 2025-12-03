class AFinalEssenceDoubleInteract : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditAnywhere)
	AKineticSplineFollowActor HydraSpline1;
	UPROPERTY(EditAnywhere)
	AKineticSplineFollowActor HydraSpline2;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossSplineRunPlatform LastPlatform;

	UPROPERTY(EditAnywhere)
	ASplineFollowCameraActor FocusCamera;

	UPROPERTY()
	FButtonMashSettings MashSettings;
	default MashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default MashSettings.Duration = 6.0;
	default MashSettings.Difficulty = EButtonMashDifficulty::Hard;
	default MashSettings.bAllowPlayerCancel = false;
	private UButtonMashComponent ButtonMashComp = nullptr;
	FHazeAcceleratedFloat AccOpen;

	UPROPERTY(DefaultComponent)
	USceneComponent CameraFocusTarget;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera2;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DestructionVFX;

	FOnButtonMashCompleted OnCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (DoubleInteract != nullptr)
			DoubleInteract.OnDoubleInteractionLockedIn.AddUFunction(this, n"HandleInteractLockedIn");
	
		OnCompleted.BindUFunction(this, n"ButtomMashCompleted");
		HydraSpline1.OnReachedEnd.AddUFunction(this,n"HandleReachedEnd");
	}

	UFUNCTION()
	private void HandleReachedEnd()
	{
		Game::Mio.ActivateCamera(FocusCamera, 2.0, this, EHazeCameraPriority::High);
		
		HydraSpline2.ActivateFollowSpline();
		Timer::SetTimer(this, n"LaunchCharacters", 2.5, false);
	}

	UFUNCTION()
	void LaunchCharacters()
	{
		//Game::Mio.DeactivateCamera(Camera2);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(DestructionVFX, LastPlatform.GetActorLocation() * LastPlatform.GetActorUpVector() * 500 , LastPlatform.GetActorRotation());
		
		for(auto Player : Game::Players)
		{
			Player.AddMovementImpulse(Player.GetMovementWorldUp() * 8600.0);
		}
		
		LastPlatform.DestroyActor();
	}

	UFUNCTION()
	private void HandleInteractLockedIn()
	{
		DoubleInteract.DisableDoubleInteractionForPlayer(Game::Mio, this);
		DoubleInteract.DisableDoubleInteractionForPlayer(Game::Zoe, this);

		UButtonMashComponent PlayerButtonMash = UButtonMashComponent::Get(Game::Zoe);
		Game::Zoe.StartButtonMash(MashSettings, this, OnCompleted);

		//Game::Mio.BlockCapabilities(CapabilityTags::StickInput, this);
		Game::Mio.StartButtonMash(MashSettings, this, OnCompleted);
		PlayerButtonMash.SetAllowButtonMashCompletion(this, false);
		// Timer::SetTimer(this, n"RemoveMashCompletionDisabler", 1.0);
		SetActorTickEnabled(true);
		ButtonMashComp = PlayerButtonMash;

		ButtonMashStarted();
	}

	void ButtonMashStarted()
	{
		Game::Mio.ActivateCamera(Camera, 2.0, this, EHazeCameraPriority::High);
		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
	}

	UFUNCTION()
	private void ButtomMashCompleted()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		/*if (Game::GetZoe().GetButtonMashProgress(this) >= 0.5)
		{
			Game::GetZoe().StopButtonMash(this);
			Game::GetMio().StopButtonMash(this);
			DoubleInteract.AddActorDisable(this);
			ButtomMashCompleted();
			
		}*/
	}
};