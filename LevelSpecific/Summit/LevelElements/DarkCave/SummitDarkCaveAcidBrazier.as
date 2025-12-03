class ASummitDarkCaveAcidBrazier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent FireEffect;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	USceneComponent GongHitLocation;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ParticleRoot;

	UPROPERTY(DefaultComponent, Attach = AcidResponseComp)
	UHazeCapsuleCollisionComponent FireCollisionComp;
	default FireCollisionComp.CapsuleHalfHeight = 700;
	default FireCollisionComp.CapsuleRadius = 500.0;
	default FireCollisionComp.SetCollisionProfileName(n"BlockAllDynamic"); 

	UPROPERTY(DefaultComponent, Attach = AcidResponseComp)
	UDeathTriggerComponent FireDeathTrigger;
	default FireDeathTrigger.Shape = FHazeShapeSettings::MakeCapsule(600, 800);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GongExtinguishDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float AcidExtinguishedDelay = 10.0;

	// UPROPERTY(EditAnywhere, Category = "Settings")
	// float SuccessfulGongResetDuration = 10.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ParticlesActivateDuration = 10.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ParticleResetDuration = 4.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ParticleTravelToSkeletonDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float BrazierMaxHealth = 30.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GongEffectDelay = 1.5;

	float BrazierCurrentHealth;

	TOptional<float> GongExtinguishedTime;
	TOptional<float> SuccessfulGongTime;
	TOptional<float> AcidExtinguishedTime;

	bool bParticlesAreReleased = false;
	bool bParticlesAreActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnHitByAcid");

		BrazierCurrentHealth = BrazierMaxHealth;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(GongExtinguishedTime.IsSet())
		{
			if(Time::GetGameTimeSince(GongExtinguishedTime.Value) >= GongExtinguishDuration)
			{
				ToggleFire(true);
				GongExtinguishedTime.Reset();
			}
		}

		if(AcidExtinguishedTime.IsSet())
		{
			if(Time::GetGameTimeSince(AcidExtinguishedTime.Value) >= AcidExtinguishedDelay)
			{
				ToggleFire(true);
				BP_ResetParticles(ParticleResetDuration);
				AcidExtinguishedTime.Reset();
			}
		}

		if(SuccessfulGongTime.IsSet())
		{
			if(!bParticlesAreActivated)
			{
				if(Time::GetGameTimeSince(SuccessfulGongTime.Value) >= GongEffectDelay)
					ActivateParticles();
			}

			// if(Time::GetGameTimeSince(SuccessfulGongTime.Value) >= SuccessfulGongResetDuration)
			// {
			// 	ToggleFire(true);
			// 	BP_ResetParticles(ParticleResetDuration);
			// 	SuccessfulGongTime.Reset();
			// }
		}

	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByAcid(FAcidHit Hit)
	{
		if(bParticlesAreReleased)
			return;

		BrazierCurrentHealth--;

		if(BrazierCurrentHealth <= 0)
		{
			ToggleFire(false);
			AcidExtinguishedTime.Set(Time::GameTimeSeconds);

			BP_ActivateParticles(ParticlesActivateDuration);
			
			BrazierCurrentHealth = BrazierMaxHealth;
		}
		else
		{
			FireEffect.SetFloatParameter(n"NormalizedHealth", BrazierCurrentHealth / BrazierMaxHealth);
		}
	}

	void HitByGongWave()
	{
		if(bParticlesAreReleased)
		{
			SuccessfulGongTime.Set(Time::GameTimeSeconds);
			GongExtinguishedTime.Reset();
			AcidExtinguishedTime.Reset();
		}
		else
		{
			ToggleFire(false);
			GongExtinguishedTime.Set(Time::GameTimeSeconds);
		}
	}

	void ActivateParticles()
	{
		BP_ActivateParticleSkeleton(ParticleTravelToSkeletonDuration);
	}

	void ToggleFire(bool bToggleOn)
	{
		if(bToggleOn)
		{
			FireEffect.Activate();
			FireDeathTrigger.EnableDeathTrigger(this);
			FireCollisionComp.RemoveComponentCollisionBlocker(this);
			FireEffect.SetFloatParameter(n"NormalizedHealth", BrazierCurrentHealth / BrazierMaxHealth);
		}
		else
		{
			FireEffect.Deactivate();
			FireDeathTrigger.DisableDeathTrigger(this);
			FireCollisionComp.AddComponentCollisionBlocker(this);
		}
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
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateParticleSkeleton(float ParticleDuration)
	{
		bParticlesAreActivated = true;
	}
};