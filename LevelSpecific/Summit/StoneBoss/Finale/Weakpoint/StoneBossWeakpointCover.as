event void FOnSerpentWeakpointDestroyed();
event void FOnSerpentWeakpointActivated();
event void FOnSerpentWeakpointDeactivated();

class AStoneBossWeakpointCover : AHazeActor
{
	UPROPERTY()
	FOnSerpentWeakpointDestroyed OnSerpentWeakpointDestroyed;

	UPROPERTY()
	FOnSerpentWeakpointActivated OnSerpentWeakpointActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Stone;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Crystal;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent CrystalExplosion;
	default CrystalExplosion.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBossWeakpointCoverCameraCapability");

	UPROPERTY(EditAnywhere)
	ABothPlayerTrigger BothPlayerTrigger;

	UPROPERTY(EditAnywhere)
	AStoneBossWeakpoint Weakpoint;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	USerpentRunCameraSettings CameraSettings;

	UPROPERTY(EditAnywhere)
	ASplineActor AcidSpline;
	UPROPERTY(EditAnywhere)
	ASplineActor TailSpline;

	UPROPERTY(EditAnywhere)
	float TailAttackDelay = 1.0;
	UPROPERTY(EditAnywhere)
	float AcidAttackDelay = 1.0;
	UPROPERTY(EditAnywhere)
	AStaticCameraActor FocusCamera;
	UPROPERTY(EditAnywhere)
	float FocusCameraDelay = 3.5;

	ADragonRunAcidDragon AcidDragon;
	ADragonRunTailDragon TailDragon;

	TPerPlayer<bool> PlayersActive;
	bool bCanActivateCamera;
	bool bWasActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidDragon = TListedActors<ADragonRunAcidDragon>().GetSingle();
		TailDragon = TListedActors<ADragonRunTailDragon>().GetSingle();

		BothPlayerTrigger.OnBothPlayersInside.AddUFunction(this, n"OnBothPlayersInside");
	}

	UFUNCTION()
	private void OnBothPlayersInside()
	{
		if (bWasActivated)
			return;
		
		if (HasControl())
			CrumbActivateAttackCheck();
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivateAttackCheck()
	{
		AcidDragon.ActivateSplineMove(AcidSpline, AcidAttackDelay, this);
		TailDragon.ActivateSplineMove(TailSpline, TailAttackDelay, this);
		Timer::SetTimer(this, n"TEMP_DelayDestruction", 3.5);

		OnSerpentWeakpointActivated.Broadcast();

		TArray<ASerpentRunCameraActor> SerpentCameras = TListedActors<ASerpentRunCameraActor>().GetArray();

		for (ASerpentRunCameraActor Camera : SerpentCameras)
		{
			Camera.ApplySettings(CameraSettings, this);
		}

		bCanActivateCamera = true;
		bWasActivated = true;
		Stone.SetHiddenInGame(true);
		Stone.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void TEMP_DelayDestruction()
	{
		CrystalExplosion.Activate();

		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayCameraShake(CameraShake, this);
		
		Crystal.SetHiddenInGame(true);
		Crystal.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		BP_GemDestroyed();

		OnSerpentWeakpointDestroyed.Broadcast();
		Weakpoint.EnableWeakpoint();
	}

	UFUNCTION(BlueprintEvent)
	void BP_GemDestroyed() {}
}