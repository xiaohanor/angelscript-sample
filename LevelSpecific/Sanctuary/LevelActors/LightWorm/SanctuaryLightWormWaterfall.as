class ASanctuaryLightWormWaterfall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WaterRoot;

	UPROPERTY(DefaultComponent, Attach = WaterRoot)
	UStaticMeshComponent WaterMeshComp;
	default WaterMeshComp.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = WaterRoot)
	UNiagaraComponent VFXComp;

	UPROPERTY(DefaultComponent, Attach = WaterRoot)
	UBoxComponent TriggerComp;


	UPROPERTY(EditInstanceOnly)
	ALightSeeker LightWorm;

	UPROPERTY()
	UNiagaraSystem SplashVFX;

	bool bWaterOpen = false;

	bool bZoeOverlaping = false;
	bool bZoeOverlapingSubtractive = false;

	bool bMioOverlaping = false;
	bool bMioOverlapingSubtractive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"HandleTriggerBeginOverlap");
		TriggerComp.OnComponentEndOverlap.AddUFunction(this, n"HandleTriggerEndOverlap");
	}

	UFUNCTION()
	private void HandleTriggerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                       UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                       bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (OtherActor == Game::Zoe)
		{
			bZoeOverlaping = true;
			PlayerBeginOverlap(Game::Zoe);
		}

		if (OtherActor == Game::Mio)
		{
			bMioOverlaping = true;
			PlayerBeginOverlap(Game::Mio);
		}
	}
	
	UFUNCTION()
	private void HandleTriggerEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (OtherActor == Game::Zoe)
		{
			bZoeOverlaping = false;
			PlayerEndOverlap(Game::Zoe);
		}

		if (OtherActor == Game::Mio)
		{
			bMioOverlaping = false;
			PlayerEndOverlap(Game::Mio);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bWaterOpen)
			if (LightWorm.RuntimeSpline.GetClosestLocationToLocation(WaterRoot.WorldLocation).Distance(WaterRoot.WorldLocation) < 100.0)
				OpenWater();

		if (bWaterOpen)
			if (LightWorm.RuntimeSpline.GetClosestLocationToLocation(WaterRoot.WorldLocation).Distance(WaterRoot.WorldLocation) > 100.0)
				CloseWater();

		if (bZoeOverlaping)
			Game::Zoe.AddMovementImpulse(FVector::UpVector * -1100.0 * DeltaSeconds);

		if (bMioOverlaping)
			Game::Mio.AddMovementImpulse(FVector::UpVector * -1100.0 * DeltaSeconds);
	}

	UFUNCTION()
	private void PlayerBeginOverlap(AHazePlayerCharacter Player)
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);	
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(SplashVFX, Player.ActorLocation);
	}

	UFUNCTION()
	private void PlayerEndOverlap(AHazePlayerCharacter Player)
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
	}

	UFUNCTION()
	private void OpenWater()
	{
		bWaterOpen = true;

		VFXComp.Activate();
		//WaterMeshComp.SetHiddenInGame(true);
	}

	UFUNCTION()
	private void CloseWater()
	{
		bWaterOpen = false;

		VFXComp.Deactivate();
		//WaterMeshComp.SetHiddenInGame(false);
	}
};