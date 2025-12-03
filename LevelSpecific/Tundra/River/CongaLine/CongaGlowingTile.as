class ACongaGlowingTile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	UMaterialInterface DanceTileMaterial;

	UPROPERTY()
	UMaterialParameterCollection MaterialParams;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UMaterialInstanceDynamic DynamicMat;

	float MaxStrength = 2;
	float BrightnessAlpha = 0.1;
	float ColorAlpha = 0;
	float InactiveAlpha = 0;
	FHazeAcceleratedFloat BrightnessAlphaSmoothed;
	FHazeAcceleratedFloat ColorAlphaSmoothed;
	float ColorLerpSpeed = 10;
	const float BrightnessLerpDuration = 0.5;

	FLinearColor CurrentColor;

	TInstigated<FLinearColor> InstigatedColor;

	bool bIsActive = false;
	bool bDiscoModeActive = false;
	float RandomDiscoTimeOffset;
	float RandomDiscoSpeed;
	float DiscoBrightnessStrength;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(DynamicMat == nullptr)
			CreateDynamicMaterial();
	}

	void CreateDynamicMaterial()
	{
		DynamicMat = Material::CreateDynamicMaterialInstance(this, DanceTileMaterial);
		Mesh.SetMaterial(0, DynamicMat);
	}

	void SetActive(bool IsActive, float AInactiveAlpha = 0.1)
	{
		BrightnessAlpha = IsActive ? MaxStrength : AInactiveAlpha;
		bIsActive = IsActive;
		InactiveAlpha = AInactiveAlpha;
	}

	void SetMaxStrength(float Strength)
	{
		MaxStrength = Strength;
		SetActive(bIsActive);
	}

	void SetDiscoMode(bool bDiscoMode, float BrightnessStrength)
	{
		bDiscoModeActive = bDiscoMode;
		DiscoBrightnessStrength = BrightnessStrength;
		
		if(bDiscoModeActive)
		{
			RandomDiscoTimeOffset = Math::RandRange(0, 10);
			RandomDiscoSpeed = Math::RandRange(0.1, 0.5);
		}
	}

	FLinearColor GetColorAndBrightness()
	{
		return CurrentColor * BrightnessAlphaSmoothed.Value;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Brightness = BrightnessAlpha;

		if(bDiscoModeActive && InstigatedColor.CurrentPriority == EInstigatePriority::Low)
		{
			Brightness = DiscoBrightnessStrength * (Math::Abs(Math::PerlinNoise1D(Time::GameTimeSeconds * RandomDiscoSpeed + RandomDiscoTimeOffset)) + 0.1);
		}

		BrightnessAlphaSmoothed.AccelerateTo(Brightness, BrightnessLerpDuration, DeltaSeconds);
		CurrentColor = Math::CInterpTo(CurrentColor, InstigatedColor.Get(), DeltaSeconds, ColorLerpSpeed);
		DynamicMat.SetVectorParameterValue(n"Global_EmissiveTint", GetColorAndBrightness());
	}

	void SetDefaultColorByIndex(int Index)
	{
		if(DynamicMat == nullptr)
			CreateDynamicMaterial();

		FLinearColor BaseColor;
		if(!GetColorByIndex(Index, BaseColor))
			return;
		
		CurrentColor = BaseColor;
		InstigatedColor.SetDefaultValue(BaseColor);
	}

	void ClearColorOverride(FInstigator Instigator)
	{
		InstigatedColor.Clear(Instigator);
	}

	/* Returns true if color could be found, false if not */
	bool GetColorByIndex(int Index, FLinearColor& Color)
	{
		if(Index < 0)
		{
			Color = FLinearColor::Black;
			return true;
		}

		TArray<FName> ParamNames = MaterialParams.VectorParameterNames;
		bool ParamFound = false;
		FLinearColor BaseColor = MaterialParams.GetVectorParameterDefaultValue(ParamNames[Index % ParamNames.Num()], ParamFound);
		if(!ParamFound)
			return false;

		Color = BaseColor;
		return true;
	}

	
	void SetDefaultColor(FLinearColor Color)
	{
		if(DynamicMat == nullptr)
			CreateDynamicMaterial();

		CurrentColor = Color;
		InstigatedColor.SetDefaultValue(Color);
	}

	void ApplyColorOverride(int Index, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		FLinearColor BaseColor;
		if(!GetColorByIndex(Index, BaseColor))
			return;

		InstigatedColor.Apply(BaseColor, Instigator, Priority);
	}

	void ApplyColorOverride(FLinearColor Color, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedColor.Apply(Color, Instigator, Priority);
	}
};