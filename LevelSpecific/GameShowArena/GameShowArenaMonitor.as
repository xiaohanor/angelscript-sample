event void FOnButtonMashStarted();
event void FOnMonitorFellDown();
class AGameShowArenaMonitor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CableMeshRoot;

	UPROPERTY(DefaultComponent, Attach = CableMeshRoot)
	UStaticMeshComponent CableMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MonitorMesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MonitorMesh02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MonitorMesh03;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MonitorMesh04;

	UPROPERTY()
	FOnMonitorFellDown OnMonitorFellDown;
	UPROPERTY()
	FOnButtonMashStarted OnButtonMashStarted;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem InitialExplosion;
	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactExplosion;

	UPROPERTY()
	FHazeTimeLike FallDownTimelike;
	default FallDownTimelike.Duration = 1.5;

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	UInteractionComponent MioInteract;
	default MioInteract.UsableByPlayers = EHazeSelectPlayer::Mio;
	default MioInteract.bShowForOtherPlayer = true;

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	UInteractionComponent ZoeInteract;
	default ZoeInteract.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default ZoeInteract.bShowForOtherPlayer = true;

	UPROPERTY(EditAnywhere, Category = "ButtonMash")
	AFocusCameraActor ButtonMashFocusCamera;
	UPROPERTY(EditAnywhere, Category = "ButtonMash")
	float ButtonMashCameraBlendInTime = 1;

	UPROPERTY(EditAnywhere, Category = "ButtonMash")
	EButtonMashDifficulty ButtonMashDifficulty = EButtonMashDifficulty::Medium;
	UPROPERTY(EditAnywhere, Category = "ButtonMash")
	float ButtonMashDuration = 3;

	TPerPlayer<bool> InteractingPlayers;

	bool bButtonMashStarted = false;
	bool bButtonMashCompleted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FallDownTimelike.BindUpdate(this, n"FallDownTimelikeUpdate");
		FallDownTimelike.BindFinished(this, n"FallDownTimelikeFinished");

		MioInteract.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		MioInteract.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");

		ZoeInteract.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
		ZoeInteract.OnInteractionStopped.AddUFunction(this, n"InteractionStopped");
	}

	UFUNCTION()
	private void FallDownTimelikeFinished()
	{
		// MeshRoot.SetHiddenInGame(true, true);
		BaseMesh01.CollisionEnabled = ECollisionEnabled::NoCollision;
		BaseMesh02.CollisionEnabled = ECollisionEnabled::NoCollision;
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactExplosion, MeshRoot.WorldLocation - FVector(0, 0, 1000));
		OnMonitorFellDown.Broadcast();
	}

	UFUNCTION()
	private void FallDownTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector(0, 0, -1650), CurrentValue));
	}

	void StartFallingDown()
	{
		CableMeshRoot.DetachFromParent(true);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(InitialExplosion, MeshRoot.WorldLocation);
		FallDownTimelike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	private void InteractionStarted(UInteractionComponent InteractionComponent,
							AHazePlayerCharacter Player)
	{
		InteractingPlayers[Player] = true;
		if (InteractingPlayers[Player] && InteractingPlayers[Player.OtherPlayer])
			InteractCompleted();
	}

	UFUNCTION(NotBlueprintCallable)
	private void InteractionStopped(UInteractionComponent InteractionComponent,
							AHazePlayerCharacter Player)
	{
		InteractingPlayers[Player] = false;
	}

	UFUNCTION()
	private void InteractCompleted()
	{
		if (bButtonMashStarted)
			return;

		bButtonMashStarted = true;

		OnButtonMashStarted.Broadcast();

		MioInteract.KickAnyPlayerOutOfInteraction();
		ZoeInteract.KickAnyPlayerOutOfInteraction();
		MioInteract.Disable(this);
		ZoeInteract.Disable(this);
		FButtonMashSettings MioMashSettings;
		MioMashSettings.bAllowPlayerCancel = false;
		MioMashSettings.Difficulty = ButtonMashDifficulty;
		MioMashSettings.Duration = ButtonMashDuration;

		FButtonMashSettings ZoeMashSettings;
		ZoeMashSettings.bAllowPlayerCancel = false;
		ZoeMashSettings.Difficulty = ButtonMashDifficulty;
		ZoeMashSettings.Duration = ButtonMashDuration;
		// ZoeMashSettings.WidgetAttachComponent = Weakpoint.ZoeSwordRoot;
		Game::Mio.ActivateCamera(ButtonMashFocusCamera, 1, this);
		Game::Zoe.ActivateCamera(ButtonMashFocusCamera, 1, this);
		ButtonMash::StartDoubleButtonMash(MioMashSettings, ZoeMashSettings, n"GameShowArenaMonitor", FOnButtonMashCompleted(this, n"OnDoubleMashCompleted"));
	}

	UFUNCTION()
	private void OnDoubleMashCompleted()
	{
		if (bButtonMashCompleted)
			return;

		Game::Mio.DeactivateCameraByInstigator(this, 1);
		Game::Zoe.DeactivateCameraByInstigator(this, 1);
		bButtonMashCompleted = true;
		StartFallingDown();
	}
}