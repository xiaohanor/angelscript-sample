struct FSolarFlareWindowSpotLights
{
	UPROPERTY()
	ASpotLight SpotLight;

	float Intensity;

	void SaveIntensity()
	{
		Intensity = SpotLight.SpotLightComponent.Intensity;
	} 
}

struct FSolarFlareGodRay
{
	UPROPERTY()
	AGodray GodRay;

	float Opacity;

	void SaveOpacity()
	{
		Opacity = GodRay.Component.Opacity;
	} 
}


class ASolarFlareWindowEffectActor : ASolarFlareWaveImpactEventActor
{
	UPROPERTY(EditAnywhere)
	TArray<FSolarFlareWindowSpotLights> SpotLights;

	UPROPERTY(EditAnywhere)
	TArray<AHazeNiagaraActor> NiagaraSystems;

	UPROPERTY(EditAnywhere)
	TArray<FSolarFlareGodRay> GodRays;

	UPROPERTY(EditAnywhere, Category = "Audio")
	UHazeAudioEvent DestructionEvent;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FHazeAudioFireForgetEventParams EventParams;

	UPROPERTY(EditAnywhere, Category = "Audio")
	APlayerTrigger PlayerWhoEnteredFirstTrigger;

	AHazePlayerCharacter TriggeredPlayer;

	ASolarFlareVOManager VOManager;

	float FlareTime;
	float Multiplier;

	bool bFirstImpact;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnSolarWaveImpactEventActorTriggered");
	
		for (AHazeNiagaraActor Niagara : NiagaraSystems)
		{
			Niagara.NiagaraComponent0.Deactivate();
			Niagara.NiagaraComponent0.SetAutoActivate(false);
		}

		for (FSolarFlareWindowSpotLights& Data : SpotLights)
		{
			Data.SaveIntensity();
			Data.SpotLight.SpotLightComponent.SetIntensity(Data.Intensity * Multiplier);
		}

		for (FSolarFlareGodRay& GodRay : GodRays)
		{
			GodRay.SaveOpacity();
			GodRay.GodRay.Component.SetGodrayOpacity(GodRay.Opacity * Multiplier);
		}

		PlayerWhoEnteredFirstTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if (VOManager == nullptr)
			VOManager = TListedActors<ASolarFlareVOManager>().GetSingle();

		if (FlareTime > 0.0)
		{
			FlareTime -= DeltaSeconds;
			Multiplier = Math::FInterpConstantTo(Multiplier, 1.0, DeltaSeconds, 1.0);
		}
		else
		{
			Multiplier = Math::FInterpConstantTo(Multiplier, 0.0, DeltaSeconds, 2.0);
		}

		for (FSolarFlareWindowSpotLights& Data : SpotLights)
		{
			Data.SpotLight.SpotLightComponent.SetIntensity(Data.Intensity * Multiplier);
		}

		for (FSolarFlareGodRay& GodRay : GodRays)
		{
			GodRay.GodRay.Component.SetGodrayOpacity(GodRay.Opacity * Multiplier);
		}
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (TriggeredPlayer == nullptr)
		{
			TriggeredPlayer = Player;
		}
	}

	UFUNCTION()
	private void OnSolarWaveImpactEventActorTriggered()
	{
		FlareTime = 1.5;
		
		for (AHazeNiagaraActor Niagara : NiagaraSystems)
		{
			Niagara.NiagaraComponent0.Activate();
		}

		if (!bFirstImpact)
		{
			bFirstImpact = true;

			//FEED IN PLAYER WHO WENT INTO TRIGGER
			VOManager.TriggerSolarHitVO(TriggeredPlayer);
		}

		if(DestructionEvent != nullptr)
		{
			EventParams.AttachComponent = Root;
			AudioComponent::PostFireForget(DestructionEvent, EventParams);
		}
	}
};