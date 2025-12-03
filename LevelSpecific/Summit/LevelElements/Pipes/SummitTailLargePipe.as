class ASummitTailLargePipe : ASummitMusicPipe
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EffectSystem;
	default EffectSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = SymbolMeshComp)
	UTeenDragonTailAttackResponseComponent TailResponse;
	default TailResponse.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLight;
	default SpotLight.SetCastShadows(false);
	default SpotLight.OuterConeAngle = 30.0;
	default SpotLight.bUseInverseSquaredFalloff = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.0;

	UPROPERTY(EditInstanceOnly)
	int MusicNoteIndex = 0;

	UMaterialInstanceDynamic DynamicMat;
	FLinearColor Color;
	float DefaultLightIntensity;

	float TargetBackOffset = -200.0;
	float CurrentBackOffset;
	float OffsetSpeed = 200.0;
	FHazeAcceleratedFloat AccelFloat;

	bool bReset = true;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TailResponse.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		StartLocation = SymbolMeshComp.RelativeLocation;
		DefaultLightIntensity = SpotLight.Intensity;
		SetEmissiveMaterial(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentBackOffset = Math::FInterpConstantTo(CurrentBackOffset, 0.0, DeltaSeconds, OffsetSpeed);
		AccelFloat.AccelerateTo(CurrentBackOffset, 0.3, DeltaSeconds);
		SymbolMeshComp.RelativeLocation = StartLocation + FVector(AccelFloat.Value, 0, 0);

		if (AccelFloat.Value > -1.0 && !bReset)
		{
			bReset = true;
			SetEmissiveMaterial(false);
			EffectSystem.Deactivate();
			USummitMusicSymbolEventHandler::Trigger_OnSymbolUnlit(this, FOnSummitSymbolLitParams(SymbolMeshComp.WorldLocation, SymbolMeshComp.WorldRotation));
		}
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!bReset)
			return;

		EffectSystem.Activate();
		ActivatePipeEvent();
		CurrentBackOffset = TargetBackOffset;
		SetEmissiveMaterial(true);
		bReset = false;

		USummitMusicSymbolEventHandler::Trigger_OnSymbolLit(this, FOnSummitSymbolLitParams(SymbolMeshComp.WorldLocation, SymbolMeshComp.WorldRotation));
		USummitTailLargePipeEventHandler::Trigger_OnNotePlayed(this, FSummitTailPipePlayed(MusicNoteIndex));
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