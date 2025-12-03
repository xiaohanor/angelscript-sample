class ULoadingTransistionEffect : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage TestImage;

	UPROPERTY(EditAnywhere)
	UMaterialInterface SurfaceMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInstanceDynamic SurfaceMaterialDynamic;
	
	UPROPERTY(EditAnywhere)
	UMaterialInterface SimulationMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInstanceDynamic SimulationMaterialDynamic;

	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Swap0;
	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Swap1;
	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Current;
	UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Previous;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{

	}

	bool bFirstFrame = true;

	UFUNCTION(BlueprintOverride) 
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(bFirstFrame)
		{
			SurfaceMaterialDynamic = Material::CreateDynamicMaterialInstance(this, SurfaceMaterial);
			SimulationMaterialDynamic = Material::CreateDynamicMaterialInstance(this, SimulationMaterial);
			
			TestImage.SetBrushFromMaterial(SurfaceMaterialDynamic);
			
			FVector2D size = SceneView::GetFullViewportResolution();
			Swap0 = Rendering::CreateRenderTarget2D(int(size.X), int(size.Y), ETextureRenderTargetFormat::RTF_RGBA16f);
			Swap1 = Rendering::CreateRenderTarget2D(int(size.X), int(size.Y), ETextureRenderTargetFormat::RTF_RGBA16f);
			Current = Swap0;
			Previous = Swap1;

			bFirstFrame = false;
		}
		
		// Swap
		if(Current == Swap0)  Current = Swap1;
		else 				  Current = Swap0;
		if(Previous == Swap0) Previous = Swap1;
		else 				  Previous = Swap0;
		
		SimulationMaterialDynamic.SetTextureParameterValue(n"TexPreviousFrame", Previous);
		Rendering::DrawMaterialToRenderTarget(Current, SimulationMaterialDynamic);

		SurfaceMaterialDynamic.SetTextureParameterValue(n"TexSimulation", Current);
	}
};