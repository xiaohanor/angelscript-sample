class AFloodFill : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Current;

	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Previous;

	UPROPERTY(EditAnywhere)
	UTexture2D Mask;
	
	UPROPERTY(EditAnywhere)
	UMaterialInterface SimulationStep;
	
	UPROPERTY()
	UMaterialInstanceDynamic SimulationStepDynamic;
	
	UPROPERTY(EditAnywhere)
	UMaterialInterface Dilate;
	
	UPROPERTY()
	UMaterialInstanceDynamic DilateDynamic;

	UPROPERTY(EditAnywhere)
	UMaterialInterface PlaneMaterial;
	
	UPROPERTY()
	UMaterialInstanceDynamic PlaneMaterialDynamic;

	UPROPERTY(EditAnywhere)
	float Fade;

	UPROPERTY()
	float FadeLast;

	UPROPERTY(EditAnywhere)
    int Resolution = 1024;

	UPROPERTY(EditAnywhere)
    float XOffset = 0.5;

	UPROPERTY(EditAnywhere)
    float YOffset = 0.5;

	UPROPERTY()
    float XOffsetLast = 0.5;

	UPROPERTY()
    float YOffsetLast = 0.5;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Visuals", Meta = (MakeEditWidget))
	FVector WidgetVisualOffset;

	UPROPERTY(EditAnywhere)
    bool bActive = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SimulationStepDynamic = Material::CreateDynamicMaterialInstance(this, SimulationStep);
		DilateDynamic = Material::CreateDynamicMaterialInstance(this, Dilate);

		Current  = Rendering::CreateRenderTarget2D(int(Resolution), int(Resolution));
		Current.AddressX = TextureAddress::TA_Clamp;
		Current.AddressY = TextureAddress::TA_Clamp;
		Rendering::ClearRenderTarget2D(Current, FLinearColor(0,0,0,0));

		Previous = Rendering::CreateRenderTarget2D(int(Resolution), int(Resolution));
		Previous.AddressX = TextureAddress::TA_Clamp;
		Previous.AddressY = TextureAddress::TA_Clamp;
		Rendering::ClearRenderTarget2D(Previous, FLinearColor(0,0,0,0));

		PlaneMaterialDynamic = Material::CreateDynamicMaterialInstance(this, PlaneMaterial);
		MeshComp.SetMaterial(0, PlaneMaterialDynamic);
	}

	int stepCount = 0;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SimulationStepDynamic.SetTextureParameterValue(n"Mask", Mask);
		SimulationStepDynamic.SetScalarParameterValue(n"Fade", Fade);
		SimulationStepDynamic.SetScalarParameterValue(n"XOffset", XOffset);
		SimulationStepDynamic.SetScalarParameterValue(n"YOffset", YOffset);

		PlaneMaterialDynamic.SetTextureParameterValue(n"TexM1", Current);
		
		XOffset = WidgetVisualOffset.X / 100.0 + 0.5;
		YOffset = WidgetVisualOffset.Y / 100.0 + 0.5;

		if(XOffset != XOffsetLast || YOffset != YOffsetLast || Fade != FadeLast)
		{
			XOffsetLast = XOffset;
			YOffsetLast = YOffset;
			FadeLast = Fade;
			Rendering::ClearRenderTarget2D(Previous, FLinearColor(0,0,0,0));
			Rendering::ClearRenderTarget2D(Current, FLinearColor(0,0,0,0));
			stepCount = 0;
		}
		
		if(stepCount < 8) // flood fill
		{
			for (int i = 0; i < 50; i++)
			{
				// swap
				UTextureRenderTarget2D Temp = Current;
				Current = Previous;
				Previous = Temp;

				SimulationStepDynamic.SetTextureParameterValue(n"Texture", Previous);

				Rendering::DrawMaterialToRenderTarget(Current, SimulationStepDynamic);
			}
		}
		else if(stepCount < 20) // dilate
		{
			for (int i = 0; i < 50; i++)
			{
				// swap
				UTextureRenderTarget2D Temp = Current;
				Current = Previous;
				Previous = Temp;

				DilateDynamic.SetTextureParameterValue(n"Texture", Previous);

				Rendering::DrawMaterialToRenderTarget(Current, DilateDynamic);
			}
		}
		stepCount++;
	}
}