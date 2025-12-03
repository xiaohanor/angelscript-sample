class ATundra_SimonSaysMonkeyKingTile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent MonkeyKingTargetPoint;

	UPROPERTY()
	UMaterialInterface DanceTileMaterial;

	UPROPERTY()
	UMaterialParameterCollection MaterialParams;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic DynamicMat;

	UPROPERTY(NotVisible, BlueprintHidden)
	ACongaLineDanceFloor DanceFloor;

	UPROPERTY(EditAnywhere)
	bool bSetDefaultColorByIndex = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bSetDefaultColorByIndex", EditConditionHides))
	int DefaultColorIndex = 0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bSetDefaultColorByIndex", EditConditionHides))
	FLinearColor DefaultColor;

	float BrightnessAlpha = 0.1;
	float ColorAlpha = 0;
	FHazeAcceleratedFloat BrightnessAlphaSmoothed;
	FHazeAcceleratedFloat ColorAlphaSmoothed;
	const float LerpDuration = .5;
	const float ColorLerpDuration = 1;

	FLinearColor CurrentColor;

	private FVector OriginalLocation;
	TInstigated<FLinearColor> InstigatedColor;
	private TArray<FInstigator> EnableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalLocation = ActorLocation;

		if(DynamicMat == nullptr)
			CreateDynamicMaterial();

		if(bSetDefaultColorByIndex)
			SetDefaultColorByIndex(DefaultColorIndex);
		else
			SetDefaultColor(DefaultColor);
	}

	FVector GetOriginalLocation()
	{
		return OriginalLocation;
	}

	void CreateDynamicMaterial()
	{
		DynamicMat = Material::CreateDynamicMaterialInstance(this, DanceTileMaterial);
		Mesh.SetMaterial(0, DynamicMat);
	}

	private void SetActive(bool bIsActive)
	{
		BrightnessAlpha = bIsActive ? 1 : 0.1;
	}

	void Enable(FInstigator Instigator)
	{
		EnableInstigators.AddUnique(Instigator);
		SetActive(IsEnabled());
	}

	void Disable(FInstigator Instigator)
	{
		EnableInstigators.RemoveSingleSwap(Instigator);
		SetActive(IsEnabled());
	}

	bool IsEnabled()
	{
		return EnableInstigators.Num() > 0;
	}

	FLinearColor GetColorAndBrightness()
	{
		return CurrentColor * BrightnessAlphaSmoothed.Value;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BrightnessAlphaSmoothed.AccelerateTo(BrightnessAlpha, LerpDuration, DeltaSeconds);

		CurrentColor = Math::CInterpTo(CurrentColor, InstigatedColor.Get(), DeltaSeconds, 10);
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

	void ResetLocationToOriginal()
	{
		ActorLocation = OriginalLocation;
	}

	void SetCollisionActive(bool bActive)
	{
		Mesh.CollisionProfileName = bActive ? n"BlockAllDynamic" : n"NoCollision";
	}
};