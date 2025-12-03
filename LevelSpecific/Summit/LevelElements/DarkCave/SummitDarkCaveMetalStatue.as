event void SummitDarkCaveMetalStatueEvent();

class ASummitDarkCaveMetalStatue : ANightQueenMetal
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ParticleRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent GongHitLocation;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GongEffectDelay = 1.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ParticleTravelToSkeletonDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ParticlesActivateDuration = 10.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ParticleResetDuration = 4.0;

	TOptional<float> SuccessfulGongTime;
	TOptional<float> StatueMeltedTime;

	bool bParticlesAreReleased = false;
	bool bParticlesAreActivated = false;

	SummitDarkCaveMetalStatueEvent OnCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnNightQueenMetalMelted.AddUFunction(this, n"OnMelted");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bParticlesAreActivated)
			return;

		if(SuccessfulGongTime.IsSet())
		{
			if(!bParticlesAreActivated)
			{
				if(Time::GetGameTimeSince(SuccessfulGongTime.Value) >= GongEffectDelay)
					ActivateParticles();
			}
		}

		if(StatueMeltedTime.IsSet())
		{
			if(Time::GetGameTimeSince(StatueMeltedTime.Value) >= ParticlesActivateDuration)
			{
				BP_ResetParticles(ParticleResetDuration);
				StatueMeltedTime.Reset();
			}
		}
	}

	void HitByGongWave()
	{
		if(bParticlesAreReleased)
		{
			SuccessfulGongTime.Set(Time::GameTimeSeconds);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMelted()
	{
		BP_ActivateParticles(ParticlesActivateDuration);
		StatueMeltedTime.Set(Time::GameTimeSeconds);
	}

	void ActivateParticles()
	{
		BP_ActivateParticleSkeleton(ParticleTravelToSkeletonDuration);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateParticles(float ParticleDuration)
	{
		bParticlesAreReleased = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ResetParticles(float ParticleDuration) 
	{
		bParticlesAreReleased = false;
		bParticlesAreActivated = false;

		TriggerRegrow();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateParticleSkeleton(float ParticleDuration)
	{
		bParticlesAreActivated = true;
		OnCompleted.Broadcast();
	}
};