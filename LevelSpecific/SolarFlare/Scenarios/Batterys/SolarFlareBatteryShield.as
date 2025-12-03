class ASolarFlareBatteryShield : ASolarFlareWaveImpactEventActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USolarFlareShieldMeshComponent ShieldMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent CollisionComp;
	default CollisionComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default CollisionComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default CollisionComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	USolarFlarePlayerCoverComponent CoverComp;
	default CoverComp.Distance = 1400.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraCompOn;
	default NiagaraCompOn.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraCompBatteryActivated;
	default NiagaraCompBatteryActivated.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent NiagaraCompOff;
	default NiagaraCompOff.SetAutoActivate(false);

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlareBatteryPerch> BatteryPerchs;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> BatteryActivatedMiniShake;

	bool bShieldOn;
	bool bShieldImpacted;

	float TurnOnTime;
	float TurnOnDuration = 0.3;

	bool bTimerRunning;

	int BatteryCounter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CoverComp.AddDisabler(this);

		OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnSolarWaveImpactEventActorTriggered");

		// SoundDef handling the full puzzle lives on this actor, so link to the EventHandlerComps of the other actors
		for(auto& Battery : BatteryPerchs)
		{
			EffectEvent::LinkActorToReceiveEffectEventsFrom(this, Battery);
			Battery.OnSolarFlareBatteryPerchActivated.AddUFunction(this, n"OnSolarFlareBatteryPerchActivated");
			Battery.OnSolarFlareBatteryPerchDeactivated.AddUFunction(this, n"OnSolarFlareBatteryPerchDeactivated");
		}
	}

	UFUNCTION()
	private void OnSolarFlareBatteryPerchActivated(AHazePlayerCharacter Player)
	{
		BatteryCounter++;
		NiagaraCompBatteryActivated.Activate();
		Player.PlayCameraShake(BatteryActivatedMiniShake, this);

	}

	UFUNCTION()
	private void OnSolarFlareBatteryPerchDeactivated()
	{
		BatteryCounter--;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		if (bShieldOn)
			return;

		// int Counter = 0;

		// for (ASolarFlareBatteryPerch Battery : BatteryPerchs)
		// {
		// 	if (Battery.bIsOn)
		// 		Counter++;
		// }

		float RegenAlpha = 0.0;

		if (BatteryCounter > 0)
		{
			if (!ShieldMeshComp.IsOn())
				ShieldMeshComp.TurnOn();

			RegenAlpha = (float(BatteryCounter) / BatteryPerchs.Num()) * 0.5;
		}

		ShieldMeshComp.SetRegenAlphaTarget(RegenAlpha);

		if (BatteryCounter == BatteryPerchs.Num() && !bShieldOn)
		{
			if (!bTimerRunning)
			{
				bTimerRunning = true;
				TurnOnTime = Time::GameTimeSeconds + TurnOnDuration;
			}

			if (Time::GameTimeSeconds >= TurnOnTime)
			{
				bShieldOn = true;
				CoverComp.RemoveDisabler(this);
				NiagaraCompOn.Activate();
				ShieldMeshComp.SetRegenAlphaTarget(1.0);

				FSolarFlareBatteryShieldEffectHandlerParams Params;
				Params.Location = ActorLocation;
				USolarFlareBatteryShieldEffectHandler::Trigger_ShieldOn(this, Params);
				CollisionComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
				
				bTimerRunning = false;
			}
		}
	}
	
	UFUNCTION()
	private void OnSolarWaveImpactEventActorTriggered()
	{
		if (bShieldOn)
			NiagaraCompOff.Activate();
		
		bShieldOn = false;
		bShieldImpacted = true;
		Timer::SetTimer(this, n"TimedCoverDisable", 1.0, false);

		for (ASolarFlareBatteryPerch Battery : BatteryPerchs)
		{
			Battery.TurnOff();
		}

		ShieldMeshComp.RunImpact();

		FSolarFlareBatteryShieldEffectHandlerParams Params;
		Params.Location = ActorLocation;
		USolarFlareBatteryShieldEffectHandler::Trigger_ShieldImpact(this, Params);
		CollisionComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
	}

	UFUNCTION()
	void TimedCoverDisable()
	{
		CoverComp.AddDisabler(this);
	}
};