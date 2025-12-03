class ASummitMusicSymbol : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SymbolMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLight;
	default SpotLight.SetCastShadows(false);
	default SpotLight.OuterConeAngle = 30.0;
	default SpotLight.bUseInverseSquaredFalloff = false;

	UPROPERTY(EditInstanceOnly)
	ASummitPipeDoor Door;

	UPROPERTY(EditInstanceOnly)
	int Side = 1;

	UMaterialInstanceDynamic DynamicMat;
	FLinearColor Color;
	float DefaultLightIntensity;

	UPROPERTY(EditInstanceOnly)
	ASummitMusicPipe Pipe;

	bool bSymbolIsComplete;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SymbolMeshComp.SetStaticMesh(Pipe.SymbolMeshComp.StaticMesh);
		SymbolMeshComp.SetRelativeRotation(Pipe.SymbolMeshComp.RelativeRotation);

		if (Side < 0)
			AttachToComponent(Door.RDoor, NAME_None, EAttachmentRule::KeepWorld);
		else
			AttachToComponent(Door.LDoor, NAME_None, EAttachmentRule::KeepWorld);

		USummitMusicSymbolEventHandler::Trigger_OnSymbolUnlit(this, FOnSummitSymbolLitParams(SymbolMeshComp.WorldLocation, SymbolMeshComp.WorldRotation));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultLightIntensity = SpotLight.Intensity;
		SetEmissiveMaterial(false);
	}

	void SetSymbolCorrect(bool bIsTailDragon)
	{
		SetEmissiveMaterial(true);
		bSymbolIsComplete = true;

		USummitMusicSymbolEventHandler::Trigger_OnSymbolLit(this, FOnSummitSymbolLitParams(SymbolMeshComp.WorldLocation, SymbolMeshComp.WorldRotation));
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbSymbolReset()
	{
		SymbolReset();
	}

	void SymbolReset()
	{
		SetEmissiveMaterial(false);
		bSymbolIsComplete = false;
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