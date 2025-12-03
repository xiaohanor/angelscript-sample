event void FOnSolarFLareFireDonutActivatedEvent();
event void FOnSolarFlareFireDonutDeactivatedEvent();

class ASolarFlareFireDonutActor : AHazeActor
{
	UPROPERTY()
	FOnSolarFLareFireDonutActivatedEvent OnSolarFlareFireDonutActivatedEvent;
	
	UPROPERTY()
	FOnSolarFlareFireDonutDeactivatedEvent OnSolarFlareFireDonutDeactivatedEvent;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(50.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	UNiagaraSystem Explosion1;
	UPROPERTY()
	UNiagaraSystem Explosion2;
	UPROPERTY()
	UNiagaraSystem Explosion3;

	//TODO Add logic for playing
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	FRuntimeFloatCurve FeedbackCurve;
	default FeedbackCurve.AddDefaultKey(0, 0);
	default FeedbackCurve.AddDefaultKey(0.5, 0.0);
	default FeedbackCurve.AddDefaultKey(0.8, 0.07);
	default FeedbackCurve.AddDefaultKey(1, 0.2);

	UPROPERTY()
	UForceFeedbackEffect ImpactRumble;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UNiagaraComponent SunExplosionComp1;
	// default SunExplosionComp1.SetAutoActivate(false);
	// UPROPERTY(DefaultComponent, Attach = Root)
	// UNiagaraComponent SunExplosionComp2;
	// default SunExplosionComp2.SetAutoActivate(false);
	// UPROPERTY(DefaultComponent, Attach = Root)
	// UNiagaraComponent SunExplosionComp3;
	// default SunExplosionComp3.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(Category = Setup)
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	UPROPERTY(Category = Setup)
	TSubclassOf<UCameraShakeBase> LoopingCameraShake;

	UPROPERTY(EditAnywhere)
	AHazePostProcessVolume PostProcessVolume;

	float DonutScale;
	float MaxScale = 3000.0;
	float MinScale = 0.05;
	float ScaleSpeed = 1200.0;
	float ScaleSpeedMultiplier;
	float RadiusAmountPerUnit = 452.5;
	float DistanceDeathCheck;

	// float PostProcessThreshold = 250000.0;
	float SpeedThreshold = 150000.0;

	FVector StartScale;

	TArray<AHazePlayerCharacter> Players;

	//Set from SolarFlareSun on spawning
	TArray<ASolarFlareWaveImpactEventActor> WaveImpactActors;
	TArray<USolarFlareFireWaveReactionComponent> ReactionComps;

	TPerPlayer<bool> bCheckedPlayerCanKill;
	TPerPlayer<float> KillTimes;

	TPerPlayer<bool> bPlayLoopingCamShake;

	private float KillTime = 0.1;
	private float MinDonutScaleSpeed = 0.038;

	float AudioImpactDistance = 5000.0;
	private bool bPlayedImpact;

	private  ASolarFlareVOManager VOManager;

	private bool bShrinkEventTriggered;

	UFUNCTION(BlueprintOverride)	
	void BeginPlay()
	{
		Players = Game::Players;
		StartScale = MeshComp.RelativeScale3D;
		DonutScale = MeshComp.RelativeScale3D.X;
		VOManager = TListedActors<ASolarFlareVOManager>().GetSingle();

		for (ASolarFlareWaveImpactEventActor ImpactActor : WaveImpactActors)
		{
			ImpactActor.SolarFlareFireDonutActivated();
		}

		for (USolarFlareFireWaveReactionComponent ReactionComp : ReactionComps)
		{
			ReactionComp.SolarFlareFireDonutActivated();
		}

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// if (SolarFlareSun::GetVFXPhase() == ESolarFlareSunVFXPhase::FinalPhase)
		// {
		// 	bool bAnyPlayerInDeathRange = false;
			
		// 	//Shrink if before player
		// 	for (AHazePlayerCharacter Player : Players)
		// 	{
		// 		float Distance = Player.GetDistanceTo(this);

		// 		if (Distance < DistanceDeathCheck && !bCheckedPlayerCanKill[Player])
		// 		{
		// 			bAnyPlayerInDeathRange = true;
		// 		}
		// 	}

		// 	if (!bShrinkEventTriggered)
		// 	{
		// 		bShrinkEventTriggered = true;

		// 		if (bAnyPlayerInDeathRange)
		// 		{
		// 			BP_FireDonutDissappear();
		// 		}
		// 		else
		// 		{
		// 			BP_FireDonutShrink();
		// 		}
		// 	}

		// 	DonutScale -= ScaleSpeed * DeltaSeconds;
		// 	DonutScale = Math::Min(DonutScale, MinScale);
		// 	MeshComp.RelativeScale3D = FVector(DonutScale, DonutScale, DonutScale / 1.5);

		// 	if (DonutScale == MinScale)
		// 	{
		// 		StopFireWave();
		// 	}

		// 	//Dissipate if after player
		// }
		// else
		DonutScale += (ScaleSpeed * GetSpeedMultiplier()) * DeltaSeconds;
		DistanceDeathCheck = DonutScale * RadiusAmountPerUnit;
		MeshComp.RelativeScale3D = FVector(DonutScale, DonutScale, DonutScale / 1.5);
		
		if (DonutScale >= MaxScale)
		{
			StopFireWave();
		}

		for (AHazePlayerCharacter Player : Players)
		{
			SendDonutDataToCameraParticles(Player);
			ApplyEnvironmentShockwave();

			float Distance = Player.GetDistanceTo(this);
			float RemainingDistance = Distance - DistanceDeathCheck;
			
			if (RemainingDistance < AudioImpactDistance && !bPlayedImpact)
			{
				FOnSolarDonutWaveImpactPlayersParams Params;
				Params.Location = Player.ActorLocation;
				USolarFlareFireDonutEffectHandler::Trigger_OnSolarDonutWaveImpactPlayers(this, Params);
				bPlayedImpact = true;
			}

			if (Distance <= DistanceDeathCheck && !bCheckedPlayerCanKill[Player])
			{
				bCheckedPlayerCanKill[Player] = true;
				bPlayLoopingCamShake[Player] = false;
				KillTimes[Player] = KillTime;
				USolarFlarePlayerComponent::Get(Player).OnSolarFlarePlayerRecievedHit.Broadcast();
				Player.PlayCameraShake(ImpactCameraShake, this);
				Player.PlayForceFeedback(ImpactRumble, false, true, this);
			}
			
			if (DistanceDeathCheck < Distance)
			{
				float FeedbackPercentage = DistanceDeathCheck / Distance;
				// PrintToScreen(f"{FeedbackPercentage=}");

				FHazeFrameForceFeedback ForceFeedback;
				ForceFeedback.LeftMotor = FeedbackCurve.GetFloatValue(FeedbackPercentage);
				ForceFeedback.RightMotor = FeedbackCurve.GetFloatValue(FeedbackPercentage);
				ForceFeedback.LeftTrigger = FeedbackCurve.GetFloatValue(FeedbackPercentage);
				ForceFeedback.RightTrigger = FeedbackCurve.GetFloatValue(FeedbackPercentage);
				Player.SetFrameForceFeedback(ForceFeedback);
				Player.PlayCameraShake(CameraShake, this, FeedbackCurve.GetFloatValue(FeedbackPercentage) * 0.75);
			}

			if (KillTimes[Player] > 0)
			{
				KillTimes[Player] -= DeltaSeconds;

				if (KillTimes[Player] > 0)
				{
					CheckKill(Player);
				}
			}

			for (ASolarFlareWaveImpactEventActor Impact : WaveImpactActors)
			{
				if (Impact.GetDistanceTo(this) < DistanceDeathCheck)
					Impact.RunBroadcastCheck(this);
			}

			for (USolarFlareFireWaveReactionComponent ReactionComp : ReactionComps)
			{
				if (ReactionComp.Owner.GetDistanceTo(this) < DistanceDeathCheck + 12000)
					ReactionComp.RunPreBroadcastCheck();

				if (ReactionComp.Owner.GetDistanceTo(this) < DistanceDeathCheck)
					ReactionComp.RunBroadcastCheck();
			}
		}
	}

	void CheckKill(AHazePlayerCharacter Player)
	{
		auto PlayerComp = USolarFlarePlayerComponent::Get(Player);
		if (PlayerComp.CanKillPlayer() && !Player.IsPlayerDead())
		{
			Player.KillPlayer(FPlayerDeathDamageParams(-FVector::ForwardVector, 25.0), DeathEffect);
			VOManager.TriggerDeathEvent(Player);
		}
	}

	void ApplyEnvironmentShockwave()
	{
		FEnvironmentShockwaveForceData ShockwaveData;
		ShockwaveData.Epicenter = GetActorLocation();
		ShockwaveData.OuterRadius = DistanceDeathCheck;
		ShockwaveData.InnerRadius = DistanceDeathCheck * 0.5;
		ShockwaveData.Strength = 1500.0;

		Environment::ApplyShockwaveForce(ShockwaveData);
	}

	void SendDonutDataToCameraParticles( AHazePlayerCharacter Player)
	{
		UPostProcessingComponent PostProcessing = UPostProcessingComponent::Get(Player);

		if(PostProcessing == nullptr)
			return;

		// check if we have added camera particles
		UNiagaraComponent Niagara = PostProcessing.CameraParticlesComponent;
		if(Niagara == nullptr)
			return;

		// const FVector DonutPos = GetActorLocation();
		// const FVector NiagaraPos = Niagara.GetWorldLocation();
		// const float DistanceBetween = DonutPos.Distance(NiagaraPos);
		// PrintToScreenScaled("Distance Between: " + DistanceBetween);
		// PrintToScreenScaled("Distance Death check " + DistanceDeathCheck);
		// PrintToScreenScaled("Donut Scale" + DonutScale);

		// send the data
		Niagara.SetNiagaraVariableVec3("DonutPos", GetActorLocation());
		Niagara.SetNiagaraVariableFloat("DonutScale", DistanceDeathCheck);
	}

	void StartFireWave(ESolarFlareSunPhase Phase)
	{
		DistanceDeathCheck = 0.0;
		SetActorTickEnabled(true);

		switch(SolarFlareSun::GetVFXPhase())
		{
			case ESolarFlareSunVFXPhase::Phase1:
				BP_FireDonutPhaseOneStart();
				break;
			case ESolarFlareSunVFXPhase::Phase2:
				BP_FireDonutPhaseTwoStart();
				break;
			case ESolarFlareSunVFXPhase::Phase3:
				BP_FireDonutPhaseThreeStart();
				break;
			case ESolarFlareSunVFXPhase::FinalPhase:
				BP_FireDonutPhaseFinalStart();
				break;
			case ESolarFlareSunVFXPhase::Implode:
				break;
			case ESolarFlareSunVFXPhase::BlackHole:
				break;
		}

		bPlayLoopingCamShake[0] = true;
		bPlayLoopingCamShake[1] = true;

		DonutScale = StartScale.X;
		MeshComp.RelativeScale3D = StartScale;
		bCheckedPlayerCanKill[0] = false;
		bCheckedPlayerCanKill[1] = false;
		OnSolarFlareFireDonutActivatedEvent.Broadcast();
	}

	FVector GetKillLocation(AHazePlayerCharacter Player)
	{
		return ActorLocation + ((Player.ActorLocation - ActorLocation).GetSafeNormal() * DistanceDeathCheck);
	}

	UFUNCTION(BlueprintEvent)
	void BP_FireDonutPhaseOneStart() {}
	UFUNCTION(BlueprintEvent)
	void BP_FireDonutPhaseTwoStart() {}
	UFUNCTION(BlueprintEvent)
	void BP_FireDonutPhaseThreeStart() {}
	UFUNCTION(BlueprintEvent)
	void BP_FireDonutPhaseFinalStart() {}

	UFUNCTION(BlueprintEvent)
	void BP_FireDonutDissappear() {}
	UFUNCTION(BlueprintEvent)
	void BP_FireDonutShrink() {}

	void StopFireWave()
	{
		SetActorTickEnabled(false);
		DestroyActor();
	}

	float GetSpeedMultiplier()
	{
		float Percent = GetAverageAbsDistToPlayers() / SpeedThreshold;
		Percent = Math::Clamp(Percent, MinDonutScaleSpeed, 1);
		return Percent;
	}

	float GetAverageAbsDistToPlayers()
	{
		FVector Average = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		FVector Direction = ActorLocation - Average;
		return Math::Abs(DistanceDeathCheck - Direction.Size());
	}

	float GetRemainingDistanceToActor(AActor Actor)
	{
		return GetDistanceTo(Actor) - DistanceDeathCheck;
	}

	bool HasImpactedPlayer()
	{
		return bPlayedImpact;
	}
};


 ///// JOCKE LOOK HERE
namespace SolarFlareFireDonutActor 
{
	float GetTimeToWaveImpact()
	{
		ASolarFlareFireDonutActor SolarFlare = TListedActors<ASolarFlareFireDonutActor>().GetSingle();
		float Scalespeed = SolarFlare.ScaleSpeed;
		float SpeedMultiplier = SolarFlare.GetSpeedMultiplier();
		// float DeltaSeconds; how to retrieve DeltaSeconds?
		
		float AvgAbsDistToPlayers = SolarFlare.GetAverageAbsDistToPlayers();
		

		float DonutScale = (Scalespeed * SpeedMultiplier)/60 ; //should be *DeltaSeconds not /60
		float TimeToImpact = AvgAbsDistToPlayers / DonutScale;
		float tempvar = 84.0;

		return TimeToImpact;
		
	/* 	 // Incomplete, for VO (Viktor & Jocke)
		ASolarFlareSun Sun = TListedActors<ASolarFlareSun>().GetSingle();
		if (!Sun.bIsFlaring)
			return (Sun.WaitTime - Time::GameTimeSeconds) + Sun.TelegraphDuration;
		return Sun.TelegraphTime  - Time::GameTimeSeconds; */
	}
};