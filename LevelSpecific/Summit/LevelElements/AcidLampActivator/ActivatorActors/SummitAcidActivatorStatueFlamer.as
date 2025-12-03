class ASummitAcidActivatorStatueFlamer : ASummitAcidActivatorActor
{
	default bIsReactivatable = true;
	default ActivateDuration = 4.0;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ActivatorLoc1;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent FlameEffect;
	default FlameEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USpotLightComponent SpotLight;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent EnergyRune;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent EyesMesh1;
	default EyesMesh1.SetHiddenInGame(true);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent EyesMesh2;
	default EyesMesh2.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USummitAcidActivatorAttachComponent AcidAttachComp;

	float SpotLightIntensity;

	FRotator StartRotTop;
	FRotator TargetRotTop;
	FRotator StartRotBottom;
	FRotator TargetRotBottom;
	float RotateAmount = 70.0;
	float MouthCloseSpeed = 150.0;

	FHazeAcceleratedFloat AccelProgressFloat;

	float MaxZ = 1.0;
	float MinimumZ = 0.02;

	float TimeActivatorLastHitByAcid = -MAX_flt;
	bool bAcidIsHitting = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SpotLightIntensity = SpotLight.Intensity;

		AccelProgressFloat.SnapTo(0.02);

		for(auto Activator : AcidActivators)
		{
			Activator.AcidResponseComp.OnAcidHit.AddUFunction(this, n"ActivatorWasHit");
		}
	}

	const float AcidHitGracePeriod = 0.1;
	UFUNCTION()
	private void ActivatorWasHit(FAcidHit Hit)
	{
		float TimeSinceLastHitByActivator = Time::GetGameTimeSince(TimeActivatorLastHitByAcid);
		if(TimeSinceLastHitByActivator > AcidHitGracePeriod)
			USummitAcidActivatorStatueFlamerEventHandler::Trigger_OnAcidSprayStartedHitting(this);

		TimeActivatorLastHitByAcid = Time::GameTimeSeconds;
		bAcidIsHitting = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = (1.0 - GetAlphaProgress()) * 5.0;

		float ClampedAlpha = GetEnergyRuneAlpha();
		
		AccelProgressFloat.AccelerateTo(ClampedAlpha, 0.25, DeltaSeconds);
		EnergyRune.SetScalarParameterValueOnMaterials(n"Blend", ClampedAlpha);

		if (Alpha < 5.0)
		{
			FlameEffect.SetNiagaraVariableFloat("SizeAlpha", Alpha / 5.0);
		}

		if(bAcidIsHitting)
		{
			float TimeSinceLastHitByActivator = Time::GetGameTimeSince(TimeActivatorLastHitByAcid);
			if(TimeSinceLastHitByActivator > AcidHitGracePeriod)
			{
				USummitAcidActivatorStatueFlamerEventHandler::Trigger_OnAcidSprayStoppedHitting(this);
				bAcidIsHitting = false;
			}
		}
	}
	UFUNCTION(BlueprintPure)
	float GetEnergyRuneAlpha() const
	{
		float ClampedAlpha = 0;
		if (IsActivatorActive())
		{
			ClampedAlpha = Math::Clamp(MaxZ * (1 - GetAlphaProgress()), MinimumZ, 1.0);
		}
		else
		{
			// AcidAlpha
			ClampedAlpha = MinimumZ;

			if (GetProgressingAcidActivator() != nullptr)
				ClampedAlpha = Math::Clamp(MaxZ * GetProgressingAcidActivator().AcidAlpha.Value, MinimumZ, 1.0);
		}

		return ClampedAlpha;
	}

	void OnAcidActivatorStarted(AAcidActivator Activator) override
	{
		Super::OnAcidActivatorStarted(Activator);
		SpotLight.SetIntensity(0.0);
		EyesMesh1.SetHiddenInGame(false);
		EyesMesh2.SetHiddenInGame(false);
		FlameEffect.Activate();

		USummitAcidActivatorStatueFlamerEventHandler::Trigger_OnFlameActivated(this);
	}

	void OnAcidActivatorStopped(AAcidActivator Activator) override
	{
		Super::OnAcidActivatorStopped(Activator);
		SpotLight.SetIntensity(SpotLightIntensity);
		EyesMesh1.SetHiddenInGame(true);
		EyesMesh2.SetHiddenInGame(true);
		FlameEffect.Deactivate();

		USummitAcidActivatorStatueFlamerEventHandler::Trigger_OnFlameDeactivated(this);
	}
};