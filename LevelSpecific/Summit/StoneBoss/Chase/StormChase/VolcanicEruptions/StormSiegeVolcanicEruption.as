class AStormSiegeVolcanicEruption : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UNiagaraComponent NiagaraComp;
	default NiagaraComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator SerpentTrigger;

	UPROPERTY(EditAnywhere)
	bool bStartActive = false;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;
	default DisableComp.AutoDisableRange = 120000;

	float DamageRadius = 1100.0;

	bool bHaveTriggered;

	UFUNCTION(BlueprintEvent)
	void BP_ActivateVolcanicEruption() {};

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (PlayerTrigger != nullptr)
			PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		if (SerpentTrigger != nullptr)
			SerpentTrigger.OnSerpentEventTriggered.AddUFunction(this, n"OnSerpentEventTriggered");

		if (bStartActive)
			ActivateVolcanoEruption();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			// Debug::DrawDebugCircle(ActorLocation + FVector::UpVector * 2000.0, DamageRadius, 12, FLinearColor::Red, 50.0, FVector::RightVector);
			FVector Delta = Player.ActorLocation - ActorLocation;
			Delta = Delta.ConstrainToPlane(ActorUpVector);
			if (Delta.Size() < DamageRadius)
			{
				if (!Player.IsPlayerDead())
					Player.KillPlayer();
			}
		}
	}

	UFUNCTION()
	private void OnSerpentEventTriggered()
	{
		ActivateVolcanoEruption();
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		ActivateVolcanoEruption();
	}

	void ActivateVolcanoEruption()
	{
		if (bHaveTriggered)
			return;

		bHaveTriggered = true;

		NiagaraComp.Activate();

		UStormSiegeVolcanicEruptionEventHandler::Trigger_OnGeyserEruption(this, FStormOnGeyserEruptionParams(ActorLocation));

		for (AHazePlayerCharacter PerPlayer : Game::Players)
			PerPlayer.PlayWorldCameraShake(CameraShake, this, ActorLocation, 15000, 30000);

		BP_ActivateVolcanicEruption();
	}
};