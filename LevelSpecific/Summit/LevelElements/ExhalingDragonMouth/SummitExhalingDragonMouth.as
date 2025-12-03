class ASummitExhalingDragonMouth : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MouthRoot;

	UPROPERTY(DefaultComponent, Attach = MouthRoot)
	UDeathTriggerComponent MouthDeathTrigger;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ASummitAirCurrent> AirCurrentClass;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector AirCurrentSize = FVector(500, 500, 2000);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AirCurrentActiveDuration = 1.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitRollingGong GongActivator;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASummitAirCurrent AirCurrent;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeBase;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(GongActivator != nullptr)
			GongActivator.OnGongHit.AddUFunction(this, n"OnGongHit");
		
		if(AirCurrent != nullptr)
			AirCurrent.OnDragonStartedAscending.AddUFunction(this, n"OnDragonStartedAscending");
	}

	UFUNCTION()
	private void OnDragonStartedAscending()
	{
		USummitExhalingDragonMouthEventHandler::Trigger_OnDragonStartedAscending(this);		
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SetAirData();
	}

	private void SetAirData()
	{
		if(AirCurrent == nullptr)
			return;

		AirCurrent.ActorLocation = AirCurrentCenter;
		AirCurrent.CurrentBox.SetBoxExtent(AirCurrentSize);
		AirCurrent.WindCurrentSystem.WorldLocation = MouthRoot.WorldLocation;
		AirCurrent.WindCurrentSystem.WorldRotation = MouthRoot.WorldRotation;
	}

	UFUNCTION()
	void TESTGONGHIT()
	{
		OnGongHit();
	}

	UFUNCTION()
	private void OnGongHit()
	{
		if(AirCurrent == nullptr)
			return;
		
		AirCurrent.RemoveDisabler(AirCurrent.StartDisabled);
		Timer::SetTimer(this, n"DisableAirCurrent", AirCurrentActiveDuration);
		USummitExhalingDragonMouthEventHandler::Trigger_OnMouthStartedBlowing(this);

		Game::Mio.PlayWorldCameraShake(CameraShakeBase, this, ActorLocation, 3000.0, 6000.0);
	}

	UFUNCTION()
	private void DisableAirCurrent()
	{
		AirCurrent.AddDisabler(AirCurrent.StartDisabled);
		USummitExhalingDragonMouthEventHandler::Trigger_OnMouthStoppedBlowing(this);
	}

	private FVector GetAirCurrentCenter() const property
	{
		return MouthRoot.WorldLocation + (FVector::UpVector * AirCurrentSize.Z);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugBox(AirCurrentCenter, AirCurrentSize, MouthRoot.WorldRotation, FLinearColor::White, 20);
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void SpawnAirCurrent()
	{
		if(AirCurrent != nullptr)
			AirCurrent.DestroyActor();

		auto NewAirCurrent = SpawnActor(AirCurrentClass, AirCurrentCenter, MouthRoot.WorldRotation);
		NewAirCurrent.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
		AirCurrent = NewAirCurrent;
		SetAirData();
	}
#endif
};