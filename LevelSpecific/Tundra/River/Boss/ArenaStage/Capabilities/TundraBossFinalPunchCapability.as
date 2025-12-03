class UTundraBossFinalPunchCapability : UTundraBossChildCapability
{
	float FinalPunchFOV = 70;
	int FinalPunchCounter = 0;
	bool bFinalPunchDealt = false;
	bool bShouldTickFinalPunchTimeDilationTimer = false;
	bool bHasStartedFinalPunchTimeDilation = false;
	bool bHasStoppedFinalPunchTimeDilation = false;
	float FinalPunchPreStartTimeDilationTimer = 0;
	float FinalPunchTimeDilationTimer = 0;
	FVector StartingOrbColor = FVector(0.416667, 0, 0.008333);
	bool bSetFinalPunchFov = false;

	bool bShouldTickFinalPunchTimer = false;
	float FinalPunchTimer = 0;
	float FinalPunchTimerDuration = 0.15;

	bool bShouldTickLastFinalPunchTimer = false;
	float LastFinalPunchTimer = 0;
	float LastFinalPunchTimerDuration = 1.6;

	bool bHasSwitchedCamera = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Boss.OnFinalPunchingThisFrame.AddUFunction(this, n"OnFinalPunchingThisFrame");
		Boss.OnLastFinalPunch.AddUFunction(this, n"OnLastFinalPunchThisFrame");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::FinalPunch)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::FinalPunch)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Game::Mio.ActivateCamera(Boss.FinalPunchCamera01, 2, this, EHazeCameraPriority::High);
		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
		Game::Zoe.BlockCapabilities(CapabilityTags::MovementInput, this);
		Game::Zoe.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Game::Zoe.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);

		bSetFinalPunchFov = true;
		Boss.HealthBarComponent.SetHealthBarEnabled(false);
		Boss.OnLastPunchStarted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bShouldTickFinalPunchTimer)
		{
			FinalPunchTimer += DeltaTime;
			if(FinalPunchTimer >= FinalPunchTimerDuration)
			{
				bShouldTickFinalPunchTimer = false;
				OnFinalPunch();
			}
		}

		if(bShouldTickLastFinalPunchTimer)
		{
			LastFinalPunchTimer += DeltaTime;
			if(LastFinalPunchTimer >= LastFinalPunchTimerDuration)
			{
				bShouldTickLastFinalPunchTimer = false;
				OnLastFinalPunch();
			}
		}

		FinalPunchTimeDilation();
		auto CamSettings = UCameraSettings::GetSettings(Game::Mio);
		CamSettings.FOV.Apply(FinalPunchFOV, this, 0.5, EHazeCameraPriority::MAX);
	}

	UFUNCTION()
	private void OnFinalPunchingThisFrame()
	{
		FinalPunchTimer = 0;
		bShouldTickFinalPunchTimer = true;
	}

	UFUNCTION()
	private void OnLastFinalPunchThisFrame()
	{
		LastFinalPunchTimer = 0;
		bShouldTickLastFinalPunchTimer = true;
		Timer::SetTimer(this, n"PreLastFinalPunch", 1.0);
	}

	void OnFinalPunch()
	{
		if(bFinalPunchDealt)
			return;
		
		FinalPunchCounter++;
		
		if(FinalPunchCounter == 2 && !bHasSwitchedCamera)
		{
			bHasSwitchedCamera = true;
			Game::Mio.ActivateCamera(Boss.FinalPunchCamera02, 1, this, EHazeCameraPriority::High);
		}

		if(FinalPunchCounter < 3)
			return;

		if(FinalPunchCounter > 8)
			return;
		
		FinalPunchFOV -= 5;
		StartingOrbColor = StartingOrbColor * 3;
		Boss.Mesh.SetVectorParameterValueOnMaterialIndex(3, n"Color", StartingOrbColor);
		Game::Mio.PlayCameraShake(Boss.FinalPunchCamShake, this);
		Boss.OrbImpactFX.Activate(true);			
	}

	UFUNCTION()
	void PreLastFinalPunch()
	{
		bShouldTickFinalPunchTimeDilationTimer = true;
		Boss.OnLastPunchSlomoStarted.Broadcast();
	}

	void OnLastFinalPunch()
	{
		bFinalPunchDealt = true;

		FinalPunchFOV -= 6;
		StartingOrbColor = StartingOrbColor * 3;
		Boss.Mesh.SetVectorParameterValueOnMaterialIndex(3, n"Color", StartingOrbColor);
		Game::Mio.PlayCameraShake(Boss.FinalPunchCamShake, this);
		Boss.OrbImpactFX.Activate(true);

		DoneWithFinalPunch();
	}

	UFUNCTION()
	void DoneWithFinalPunch()
	{
		TimeDilation::StopWorldTimeDilationEffect(this);
		Boss.OnFinalPunchDealt.Broadcast();

		Game::Zoe.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Game::Zoe.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Game::Zoe.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
	}

	void FinalPunchTimeDilation()
	{
		if(bShouldTickFinalPunchTimeDilationTimer)
		{
			FinalPunchPreStartTimeDilationTimer += Time::UndilatedWorldDeltaSeconds;

			if(FinalPunchPreStartTimeDilationTimer >= 0.1)
			{
				if(!bHasStartedFinalPunchTimeDilation)
				{
					bHasStartedFinalPunchTimeDilation = true;
					FTimeDilationEffect Time;
					Time.TimeDilation = 0.1;
					Time.BlendInDurationInRealTime = 0.25;
					Time.BlendOutDurationInRealTime = 0.25;
					TimeDilation::StartWorldTimeDilationEffect(Time, this);
					FinalPunchTimeDilationTimer += Time::UndilatedWorldDeltaSeconds;
				}

				FinalPunchTimeDilationTimer += Time::UndilatedWorldDeltaSeconds;
				if(FinalPunchTimeDilationTimer > 1.5)
				{
					if(!bHasStoppedFinalPunchTimeDilation)
					{
						bHasStoppedFinalPunchTimeDilation = true;
						TimeDilation::StopWorldTimeDilationEffect(this);
						FinalPunchTimeDilationTimer += Time::UndilatedWorldDeltaSeconds;
						bShouldTickFinalPunchTimeDilationTimer = false;
					}
				}
			}
		}
	}
};