class ASummitAcidSmallPipe : ASummitMusicPipe
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EffectSystem;
	default EffectSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLight;
	default SpotLight.SetCastShadows(false);
	default SpotLight.OuterConeAngle = 30.0;
	default SpotLight.bUseInverseSquaredFalloff = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent InvisibleAcidCollision;
	default InvisibleAcidCollision.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = InvisibleAcidCollision)
	UAcidResponseComponent AcidResponse;
	default AcidResponse.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = InvisibleAcidCollision)
	UTeenDragonAcidAutoAimComponent AutoAimComp;
	default AutoAimComp.AutoAimMaxAngle = 10.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.0;

	UPROPERTY(EditInstanceOnly)
	int MusicNoteIndex = 0;

	UMaterialInstanceDynamic DynamicMat;
	FLinearColor Color;
	float DefaultLightIntensity;

	float BufferTime = 0.5;
	float TimeSinceLastHit;
	bool bReset = true;
	bool bMaterialLit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponse.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		DefaultLightIntensity = SpotLight.Intensity;
		SetEmissiveMaterial(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TimeSinceLastHit += DeltaSeconds;

		if (!bReset && TimeSinceLastHit > BufferTime)
		{
			bReset = true;
			SetEmissiveMaterial(false);
			EffectSystem.Deactivate();
			USummitMusicSymbolEventHandler::Trigger_OnSymbolUnlit(this, FOnSummitSymbolLitParams(SymbolMeshComp.WorldLocation, SymbolMeshComp.WorldRotation));
		}
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		TimeSinceLastHit = 0;
		
		if (!bReset)
			return;

		EffectSystem.Activate();
		ActivatePipeEvent();
		SetEmissiveMaterial(true);

		bReset = false;

		USummitMusicSymbolEventHandler::Trigger_OnSymbolLit(this, FOnSummitSymbolLitParams(SymbolMeshComp.WorldLocation, SymbolMeshComp.WorldRotation));
		USummitAcidSmallPipeEventHandler::Trigger_OnNotePlayed(this, FSummitAcidPipePlayed(MusicNoteIndex));
	}

	UFUNCTION()
	void SetEmissiveMaterial(bool bIsOn)
	{
		if (DynamicMat == nullptr)
		{
			DynamicMat = SymbolMeshComp.CreateDynamicMaterialInstance(0);
			Color = DynamicMat.GetVectorParameterValue(n"Tint_D_Emissive");
		}

		if (bIsOn)
		{
			DynamicMat.SetVectorParameterValue(n"Tint_D_Emissive", Color * 9.0);
			SpotLight.SetIntensity(DefaultLightIntensity);
		}
		else
		{
			DynamicMat.SetVectorParameterValue(n"Tint_D_Emissive", Color * 0.0);
			SpotLight.SetIntensity(0.0);
		}
	}
};