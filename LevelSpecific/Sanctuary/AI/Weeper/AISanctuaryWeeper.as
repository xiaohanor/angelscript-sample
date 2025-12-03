UCLASS(Abstract)
class AAISanctuaryWeeper : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperBehaviourCompoundCapability");

	private bool bFadeIndicator;
	private float IndicatorValue;
	private float FadeSpeed = 10.0;
	private TArray<UStaticMeshComponent> Indicators;

	// UPROPERTY(DefaultComponent)
	// USanctuaryWeeperViewComponent ViewComp;

	UPROPERTY(DefaultComponent)
	USanctuaryWeeperFreezeComponent FreezeComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USceneComponent MovementIndicator;

	UPROPERTY(DefaultComponent)
	USanctuaryWeeperArtifactResponseComponent ArtifactResponseComp;

	USanctuaryWeeperSettings WeeperSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		WeeperSettings = USanctuaryWeeperSettings::GetSettings(this);
		MovementIndicator.GetChildrenComponentsByClass(UStaticMeshComponent, true, Indicators);
		for(UStaticMeshComponent Indicator: Indicators)
		{
			Indicator.SetColorParameterValueOnMaterialIndex(0, n"BaseColor", FLinearColor(1.0, 1.0, 1.0));
		}
		FreezeComp.OnFreeze.AddUFunction(this, n"OnFreeze");
		FreezeComp.OnUnfreeze.AddUFunction(this, n"OnUnfreeze");
	}

	UFUNCTION()
	private void OnUnfreeze()
	{
		bFadeIndicator = false;
	}

	UFUNCTION()
	private void OnFreeze()
	{
		bFadeIndicator = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bFadeIndicator && IndicatorValue > 0)
			IndicatorValue -= DeltaSeconds * WeeperSettings.FreezeIndicatorSpeed;

		if(!bFadeIndicator && IndicatorValue < 100)
			IndicatorValue += DeltaSeconds * WeeperSettings.FreezeIndicatorSpeed;

		for(UStaticMeshComponent Indicator: Indicators)
		{
			Indicator.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", FLinearColor(IndicatorValue, 0, 0));
		}
	}

	UFUNCTION(BlueprintCallable)
	void PermanentFreeze()
	{
		FreezeComp.bPermanentFreeze = true;
	}

	UFUNCTION(BlueprintCallable)
	void RemovePermanentFreeze()
	{
		FreezeComp.bPermanentFreeze = false;
	}
}

UCLASS(Abstract)
class AAISanctuaryWeeper2D : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Remove(n"BasicAIDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryWeeperBehaviourCompoundCapability");

	private bool bFadeIndicator;
	private float IndicatorValue;
	private float FadeSpeed = 10.0;
	private TArray<UStaticMeshComponent> Indicators;

	TArray<ASanctuaryWeeperArtifact> Illuminators;

	bool bHasBeenAwaken;

	UPROPERTY(EditAnywhere)
	bool bStartFrozen = false;
	// UPROPERTY(DefaultComponent)
	// USanctuaryWeeper2DViewComponent ViewComp;

	UPROPERTY(DefaultComponent)
	USanctuaryWeeperFreezeComponent FreezeComp;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Head")
	USceneComponent MovementIndicator;

	UPROPERTY(DefaultComponent)
	USanctuaryWeeperArtifactResponseComponent ArtifactResponseComp;

	UPROPERTY(DefaultComponent)
	USanctuaryWeeperLightBirdResponseComponent LightBirdResponseComp;

	UPROPERTY(DefaultComponent)
	USanctuaryLightOrbPulseResponseComponent LightOrbPulseResponse;

	USanctuaryWeeperSettings WeeperSettings;

	UFUNCTION(DevFunction)
	void Burn()
	{
		HealthComp.TakeDamage(100, EDamageType::Fire, Game::Mio);
	}
	UFUNCTION(DevFunction)
	void Stab()
	{
		HealthComp.TakeDamage(100, EDamageType::MeleeSharp, Game::Mio);
	}
	UFUNCTION(DevFunction)
	void Squish()
	{
		HealthComp.TakeDamage(100, EDamageType::MeleeBlunt, Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		WeeperSettings = USanctuaryWeeperSettings::GetSettings(this);

		MovementIndicator.GetChildrenComponentsByClass(UStaticMeshComponent, true, Indicators);
		for(UStaticMeshComponent Indicator: Indicators)
		{
			Indicator.SetColorParameterValueOnMaterialIndex(0, n"BaseColor", FLinearColor(1.0, 1.0, 1.0));
		}

		FreezeComp.OnFreeze.AddUFunction(this, n"OnFreeze");
		FreezeComp.OnUnfreeze.AddUFunction(this, n"OnUnfreeze");


		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnIlluminated");

		LightOrbPulseResponse.OnPulseImpact.AddUFunction(this, n"OnPulseImpact");
		LightOrbPulseResponse.OnPulseEnd.AddUFunction(this, n"OnPulseEnd");


		if(bStartFrozen)
			PermanentFreeze();
		else
			Awaken();
		
	}


	UFUNCTION()
	private void OnPulseImpact()
	{
		if(!IsCapabilityTagBlocked(n"Behaviour"))
			BlockCapabilities(n"Behaviour", this);
	}

	UFUNCTION()
	private void OnPulseEnd()
	{
		if(IsCapabilityTagBlocked(n"Behaviour"))
			UnblockCapabilities(n"Behaviour", this);

	}

	UFUNCTION()
	void OnIlluminated(ASanctuaryWeeperLightBird LightBird)
	{
		if(!bHasBeenAwaken)
			return;
		
		// PermanentFreeze();
		SetChaseMoveSpeed(WeeperSettings.FrozenSpeed);
	}

	UFUNCTION()
	private void OnUnIlluminated(ASanctuaryWeeperLightBird LightBird)
	{
		if(!bHasBeenAwaken)
			return;

		// RemovePermanentFreeze();
		
		UBasicAISettings::ClearChaseMoveSpeed(this, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintCallable)
	void SetChaseMoveSpeed(float Speed)
	{
		UBasicAISettings::SetChaseMoveSpeed(this, Speed, this, EHazeSettingsPriority::Gameplay);

	}



	UFUNCTION()
	private void OnUnfreeze()
	{
		bFadeIndicator = false;
		if(WeeperSettings.FreezeHideIn2D)
			AddActorVisualsBlock(this);
	}

	UFUNCTION()
	private void OnFreeze()
	{
		bFadeIndicator = true;
		if(WeeperSettings.FreezeHideIn2D)
			RemoveActorVisualsBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bFadeIndicator && IndicatorValue > 0)
			IndicatorValue -= DeltaSeconds * WeeperSettings.FreezeIndicatorSpeed;

		if(!bFadeIndicator && IndicatorValue < 100)
			IndicatorValue += DeltaSeconds * WeeperSettings.FreezeIndicatorSpeed;

		for(UStaticMeshComponent Indicator: Indicators)
		{
			Indicator.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", FLinearColor(IndicatorValue, 0, 0));
		}
	}
	UFUNCTION(BlueprintCallable)
	void Awaken()
	{
		bHasBeenAwaken = true;
		RemovePermanentFreeze();

	}

	UFUNCTION(BlueprintCallable)
	void PermanentFreeze()
	{
		FreezeComp.bPermanentFreeze = true;
	}

	UFUNCTION(BlueprintCallable)
	void RemovePermanentFreeze()
	{
		FreezeComp.bPermanentFreeze = false;
	}
}