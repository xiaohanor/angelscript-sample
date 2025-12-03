event void FOnSolarFlareActivateWave();
event void FOnSolarFlareNewFlareCreated(ASolarFlareFireDonutActor NewDonut);
event void FOnSolarFlareDeactivateWave();
event void FOnSolarFlareSunStartBuildup();
event void FOnSolarFlareActivateBlackHole();

enum ESolarFlareSunPhase
{
	Phase1,
	Phase2,
	Phase3,
	Phase4,
	Phase5,
	Phase6,
	Phase7,
	Phase8,
	Phase9,
	Phase10,
	FinalPhase,
	Implode,
	BlackHole,
}

enum ESolarFlareSunVFXPhase
{
	Phase1,
	Phase2,
	Phase3,
	FinalPhase,
	Implode,
	BlackHole,
}

namespace SolarFlareSun
{
	ESolarFlareSunVFXPhase GetVFXPhase()
	{
		ASolarFlareSun Sun = TListedActors<ASolarFlareSun>().GetSingle();

		if (Sun.Phase >= ESolarFlareSunPhase(0) && Sun.Phase < ESolarFlareSunPhase(3))
		{
			return ESolarFlareSunVFXPhase::Phase1;
		}
		else if (Sun.Phase >= ESolarFlareSunPhase(3) && Sun.Phase < ESolarFlareSunPhase(7))
		{
			return ESolarFlareSunVFXPhase::Phase2;
		}
		else if (Sun.Phase >= ESolarFlareSunPhase(7) && Sun.Phase < ESolarFlareSunPhase(10))
		{
			return ESolarFlareSunVFXPhase::Phase3;
		}
		else if (Sun.Phase == ESolarFlareSunPhase(10))
		{
			return ESolarFlareSunVFXPhase::FinalPhase;
		}
		else if (Sun.Phase == ESolarFlareSunPhase(11))
		{
			return ESolarFlareSunVFXPhase::Implode;
		}
		else 
		{
			return ESolarFlareSunVFXPhase::BlackHole;
		}
	}

	float GetTimeToWaveImpact()
	{ // Incomplete, for VO (Viktor & Jocke)
		ASolarFlareSun Sun = TListedActors<ASolarFlareSun>().GetSingle();
		if (!IsValid(Sun))
			return -1.0;
		if (!Sun.bIsFlaring)
			return (Sun.WaitTime - Time::GameTimeSeconds) + Sun.TelegraphDuration;
		return Sun.TelegraphTime  - Time::GameTimeSeconds;
	}

	//Return negative if no donut around
	float GetSecondsTillHit(float DeltaTime)
	{
		ASolarFlareSun Sun = TListedActors<ASolarFlareSun>().GetSingle();
		if (!IsValid(Sun))
			return -1.0;

		ASolarFlareFireDonutActor FireDonut = Sun.CurrentFireDonut;

		if (FireDonut != nullptr && !FireDonut.IsActorBeingDestroyed() && !FireDonut.HasImpactedPlayer())
		{
			FVector AvgPos = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
			float DistanceToPlayer = (FireDonut.ActorLocation - AvgPos).Size();
			float Time = Math::Abs((FireDonut.DonutScale * FireDonut.RadiusAmountPerUnit) - DistanceToPlayer) / FireDonut.ScaleSpeed * DeltaTime;
			return Math::Clamp(Time, 0, 10000.0);
		}
		else
		{
			return -1.0;
		}
	}

	bool IsPlayerInCover(AHazePlayerCharacter Player)
	{
		USolarFlarePlayerComponent CoverComp = USolarFlarePlayerComponent::Get(Player);

		if (CoverComp != nullptr)
		{
			return CoverComp.HasNoCover() == false; 
		}

		return false;
	}
}

class ASolarFlareSun : AHazeActor
{
	UPROPERTY()
	FOnSolarFlareActivateWave OnSolarFlareActivateWave;

	UPROPERTY()
	FOnSolarFlareNewFlareCreated OnSolarFlareNewFlareCreated;

	UPROPERTY()
	FOnSolarFlareDeactivateWave OnSolarFlareDeactivateWave;

	UPROPERTY()
	FOnSolarFlareSunStartBuildup OnSolarFlareSunStartBuildup; 

	UPROPERTY()
	FOnSolarFlareActivateBlackHole OnSolarFlareActivateBlackHole;

	UPROPERTY()
	UMaterialInterface BlurHorizontal;
	
	UPROPERTY()
	UMaterialInterface BlurVertical;

	UPROPERTY()
	ESolarFlareSunPhase Phase;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoom;

	UPROPERTY(DefaultComponent, Attach = MeshRoom)
	UNiagaraComponent SunSystem;

	UPROPERTY(DefaultComponent, Attach = MeshRoom)
	UNiagaraComponent SunChargeUp;
	default SunChargeUp.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareSunFlareCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareSunSkyCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareSunPostProcessingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareSunBlackHolePullCapability");

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(DefaultComponent)
	private USolarFlarePlayerCoverAudioManager CoverAudioManager;
	USolarFlarePlayerCoverAudioManager GetSolarFlareCoverAudioManager() const
	{
		return CoverAudioManager;
	}
	
	UPROPERTY(EditAnywhere)
	AHazePostProcessVolume PostProcessVolume;

	UPROPERTY(EditAnywhere)
	ASolarFlareButtonMashLauncher MashLauncher;

	UPROPERTY(EditAnywhere)
	ASolarFlareWaveEmitter WaveEmitter;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve PostProcessIntensityCurve;
	default PostProcessIntensityCurve.AddDefaultKey(0.0, 0.0);
	default PostProcessIntensityCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	TSubclassOf<ASolarFlareFireDonutActor> FireDonutClass;
	ASolarFlareFireDonutActor CurrentFireDonut;

	TArray<ASolarFlareWaveImpactEventActor> WaveImpactActors;
	TArray<USolarFlareFireWaveReactionComponent> ReactionComps;

	UPROPERTY()
	float SunSizeAlpha = 1.0;

	UPROPERTY()
	FRuntimeFloatCurve SunSizeCurve;
	default SunSizeCurve.AddDefaultKey(0, 1);
	default SunSizeCurve.AddDefaultKey(1, 0);

	TArray<ASolarFlareEffectActor> EffectActors; 

	bool bSolarFlareSunActive = true;
	bool bOneTimeTelegraphUsed;
	bool bSolarFlareOneTimeActive;

	bool bIsFlaring;

	UPROPERTY(EditAnywhere)
	float WaitDuration = 5.0;
	float WaitTime;
	
	float TelegraphDuration = 3.0;
	float OneTimeOriginalTelegraphDuration;
	float TelegraphTime;
	
	float FireDuration = 0.4;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetSolarFlareActive();
		ChangeSunPhase(ESolarFlareSunPhase::Phase1);
		EffectActors = TListedActors<ASolarFlareEffectActor>().GetArray();
	}

	UFUNCTION()
	void SetSolarFlareInactive()
	{
		if(HasControl())
			NetSetSolarFlareInactive();
	}

	UFUNCTION(NetFunction)
	void NetSetSolarFlareInactive()
	{
		bSolarFlareSunActive = false;
	}

	UFUNCTION()
	void SetSolarFlareActive()
	{
		if (HasControl())
			NetSetSolarFlareActive();
	}

	UFUNCTION(NetFunction)
	void NetSetSolarFlareActive()
	{
		bSolarFlareSunActive = true;
		WaitTime = Time::GameTimeSeconds + WaitDuration;
	}

	//Only use from progress points
	UFUNCTION()
	void ForceResetWaitDuration(float NewDuration)
	{
		if (HasControl())
			NetForceResetWaitDuration(NewDuration);
	}

	//Only use from progress points
	UFUNCTION(NetFunction)
	void NetForceResetWaitDuration(float NewDuration)
	{
		WaitDuration = NewDuration;
		//-2.5... now accounts for time between actual impact, and when the next one comes.
		//This is so that the first wait time is not longer than consecutive wait times (waittime starts ticking the moment the wave releases, not when it hits)
		WaitTime = Time::GameTimeSeconds + WaitDuration - 2.5;
	}

	void ActivateTelegraph()
	{
		SunChargeUp.Activate();
		BP_TriggerTelegraphSequence();
		OnSolarFlareSunStartBuildup.Broadcast();
	}

	UFUNCTION()
	void SetWaitDuration(float NewDuration)
	{
		if (HasControl())
			NetSetWaitDuration(NewDuration);
	}

	UFUNCTION(NetFunction)
	void NetSetWaitDuration(float NewDuration)
	{
		WaitDuration = NewDuration;
		FOnSolarFlareSunTimingsChangedParams Params;
		Params.NewTelegraphDuration = TelegraphDuration;
		Params.NewWaitDuration = WaitDuration;
		Params.TotalTimeDuration = TelegraphDuration + WaitDuration;
		USolarFlareSunEffectHandler::Trigger_OnSunTimingsChanged(this, Params);
	}

	UFUNCTION()
	void ManualActivateSunFlareSequence()
	{
		if (HasControl())
			NetManualActivateSunFlareSequence();
	}

	UFUNCTION(NetFunction)
	void NetManualActivateSunFlareSequence()
	{
		if (bIsFlaring)
			return;

		if (!bSolarFlareSunActive)
			bSolarFlareSunActive = true;
		
		//Forces sun flare capability to activate
		WaitTime = 0.0;
	}

	UFUNCTION()
	void OneTimeSunFlareActivation(float OneTimeTelegraphDuration = 3.0)
	{
		if (HasControl())
			NetOneTimeSunFlareActivation(OneTimeTelegraphDuration);
	}

	UFUNCTION(NetFunction)
	void NetOneTimeSunFlareActivation(float OneTimeTelegraphDuration = 3.0)
	{
		if (bIsFlaring)
			return;

		if (!bSolarFlareSunActive)
			bSolarFlareOneTimeActive = true;
		
		//Forces sun flare capability to activate
		WaitTime = 0.0;

		if (TelegraphDuration != OneTimeTelegraphDuration)
		{
			OneTimeOriginalTelegraphDuration = TelegraphDuration;
			TelegraphDuration = OneTimeTelegraphDuration;
			bOneTimeTelegraphUsed = true;
		}
	}

	void SpawnFireDonut()
	{
		if (Phase != ESolarFlareSunPhase::FinalPhase && Phase != ESolarFlareSunPhase::BlackHole)
		{
			CurrentFireDonut = SpawnActor(FireDonutClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
			CurrentFireDonut.WaveImpactActors = WaveImpactActors;
			CurrentFireDonut.ReactionComps = ReactionComps;
			FinishSpawningActor(CurrentFireDonut);

			if (CurrentFireDonut == nullptr)
				return;
			
			CurrentFireDonut.StartFireWave(Phase);
			OnSolarFlareNewFlareCreated.Broadcast(CurrentFireDonut);
		}
		else
		{
			SetSolarFlareInactive();
		}
	}

	UFUNCTION()
	bool IsSolarFlareWaveActive()
	{
		return bIsFlaring == true;
	}

	UFUNCTION()
	void SetTelegraphDuration(float NewDuration)
	{
		if (HasControl())
			NetSetTelegraphDuration(NewDuration);
	}

	UFUNCTION(NetFunction)
	private void NetSetTelegraphDuration(float NewDuration)
	{
		TelegraphDuration = NewDuration;
		FOnSolarFlareSunTimingsChangedParams Params;
		Params.NewTelegraphDuration = TelegraphDuration;
		Params.NewWaitDuration = WaitDuration;
		Params.TotalTimeDuration = TelegraphDuration + WaitDuration;
		USolarFlareSunEffectHandler::Trigger_OnSunTimingsChanged(this, Params);
	}

	UFUNCTION()
	float GetTelegraphDuration()
	{
		return Math::Abs(TelegraphDuration);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_TriggerTelegraphSequence() {}

	UFUNCTION(BlueprintEvent)
	void BP_PhaseOneSet() {}
	UFUNCTION(BlueprintEvent)
	void BP_PhaseTwoSet() {}
	UFUNCTION(BlueprintEvent)
	void BP_PhaseThreeSet() {}
	UFUNCTION(BlueprintEvent)
	void BP_PhaseFinalSet() {}
	UFUNCTION(BlueprintEvent)
	void BP_PhaseImplodeSet() {}
	UFUNCTION(BlueprintEvent)
	void BP_PhaseBlackHoleSet() {}

	UFUNCTION()
	void ChangeSunPhase(ESolarFlareSunPhase NewPhase)
	{
		if(HasControl())
			NetChangeSunPhase(NewPhase);
	}

	UFUNCTION(NetFunction)
	void NetChangeSunPhase(ESolarFlareSunPhase NewPhase)
	{
		Phase = NewPhase;

		FOnSolarFlareSunPhaseChangedParams Params;
		Params.NewPhase = NewPhase;
		USolarFlareSunEffectHandler::Trigger_OnPhaseChanged(this, Params);

		switch(SolarFlareSun::GetVFXPhase())
		{
			case ESolarFlareSunVFXPhase::Phase1:
				BP_PhaseOneSet();
				break;
			case ESolarFlareSunVFXPhase::Phase2:
				BP_PhaseTwoSet();
				break;
			case ESolarFlareSunVFXPhase::Phase3:
				BP_PhaseThreeSet();
				break;
			case ESolarFlareSunVFXPhase::FinalPhase:
				BP_PhaseFinalSet();
				for (ASolarFlareEffectActor EffectActor : EffectActors)
					EffectActor.AddActorDisable(this);
				break;
			case ESolarFlareSunVFXPhase::Implode:
				BP_PhaseImplodeSet();
				break;
			case ESolarFlareSunVFXPhase::BlackHole:
				BP_PhaseBlackHoleSet();
				OnSolarFlareActivateBlackHole.Broadcast();
				break;
		}
	}

	void SetSunSizeAlpha(float NewAlpha)
	{
		SunSizeAlpha = NewAlpha;
	}

	void UpdateAlpha(float UpdateAlpha)
	{
		// PrintToScreen(f"{SunSizeCurve.GetFloatValue(UpdateAlpha)=}");
		BP_UpdateAlpha(SunSizeCurve.GetFloatValue(UpdateAlpha));
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateAlpha(float Alpha) {}

	UFUNCTION()
	float GetSecondsTillHit(float DeltaTime) const
	{
		return SolarFlareSun::GetSecondsTillHit(DeltaTime);
	}

	//DEV FUNCTIONS
	UFUNCTION(DevFunction)
	void DevPhaseOne()
	{
		Phase = ESolarFlareSunPhase::Phase1;
		BP_PhaseOneSet();
	}

	UFUNCTION(DevFunction)
	void DevPhaseTwo()
	{
		Phase = ESolarFlareSunPhase::Phase2;
		BP_PhaseTwoSet();
	}

	UFUNCTION(DevFunction)
	void DevPhaseThree()
	{
		Phase = ESolarFlareSunPhase::Phase3;
		BP_PhaseThreeSet();
	}

	UFUNCTION(DevFunction)
	void DevPhaseFinal()
	{
		Phase = ESolarFlareSunPhase::FinalPhase;
		BP_PhaseFinalSet();
	}

	UFUNCTION(DevFunction)
	void DevBlackHole()
	{
		Phase = ESolarFlareSunPhase::BlackHole;
		BP_PhaseBlackHoleSet();
	}
}