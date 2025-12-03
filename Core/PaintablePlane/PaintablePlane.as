
// to save some performance this blueprint is assumed to be axis-aligned.

enum EPaintablePlaneType
{
	Plane,
	Volume,
}

class APaintablePlane : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UBoxComponent TriggerArea;
	default TriggerArea.SetCollisionProfileName(n"Trigger");
	default TriggerArea.BoxExtent = FVector(500.0, 500.0, 500.0);

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent PreviewMesh;
    default PreviewMesh.CollisionProfileName = n"NoCollision";

	// This needs to be an FLinearColor because that is the data the GPU-side copy stores.
	UPROPERTY(Category = "zzInternal", Transient, NotEditable)
	TArray<FLinearColor> CPUSideData;

	//UPROPERTY(EditAnywhere)
	EPaintablePlaneType PlaneType = EPaintablePlaneType::Plane;

	UPROPERTY(EditAnywhere)
	int ResolutionX = 16;

	UPROPERTY(EditAnywhere)
	int ResolutionY = 16;

	//UPROPERTY(EditAnywhere, Meta = (EditCondition="PlaneType == EPaintablePlaneType::Volume", EditConditionHides))
	int ResolutionZ = 1;
	
	UPROPERTY(EditAnywhere)
	bool PreviewCPUData = false;

	UPROPERTY(EditAnywhere)
	bool PreviewGPUData = false;
	
	
	UPROPERTY(EditAnywhere)
	bool CPUDataEnabled = true;

	UPROPERTY(EditAnywhere)
	bool GPUDataEnabled = true;
	

    UPROPERTY()
    UStaticMesh PreviewMeshMesh;

    UPROPERTY()
    UMaterialInterface PreviewMaterial;

	//UPROPERTY()
	UTextureRenderTargetVolume PaintTextureVolume;



	// Texture used on the actual materials in the scene
	UPROPERTY()
	UTextureRenderTarget2D PaintTexture2DMaterialOut;

	UPROPERTY()
	UTextureRenderTarget2D PaintTexture2D;

	UPROPERTY()
	UTextureRenderTarget2D PaintTexture2DLastFrame;

	UPROPERTY()
	UTextureRenderTarget2D PaintTexture2DTarget1;

	UPROPERTY()
	UTextureRenderTarget2D PaintTexture2DTarget2;


	UPROPERTY()
	UMaterialInterface DrawBox2DMaterial;

	UPROPERTY()
	UMaterialInstanceDynamic DrawBox2DMaterialDynamic;
	
	UPROPERTY()
	UMaterialInterface CopyTexture2DMaterial;

	UPROPERTY()
	UMaterialInstanceDynamic CopyTexture2DMaterialDynamic;


	bool IsInVolume(FVector WorldLocation)
	{
		FVector TexturePosition = WorldLocationToTextureLocation(WorldLocation);
		return TexturePosition.X >= 0.0 && TexturePosition.X <= 1.0 && 
			   TexturePosition.Y >= 0.0 && TexturePosition.Y <= 1.0 && 
			   TexturePosition.Z >= 0.0 && TexturePosition.Z <= 1.0;
	}

	FVector Resolution()
	{
		return FVector(ResolutionX, ResolutionY, ResolutionZ);
	}

	// Transformations:
	FVector WorldLocationToTextureLocation(FVector WorldLocation)
	{
		FVector TexturePosition = GetActorTransform().InverseTransformPosition(WorldLocation) / 1000.0;
		//FVector TexturePosition = WorldLocation - GetActorLocation();
		//TexturePosition /= (GetActorScale3D() * 1000.0);
		TexturePosition += FVector(0.5, 0.5, 0.5); // Textures are between 0, 1 not -0.5, 0.5
		return TexturePosition;
	}

	FVector WorldSizeToTextureSize(FVector WorldSize)
	{
		return WorldSize / (GetActorScale3D() * 2000.0);
	}

	FVector TextureLocationToWorldLocation(FVector TextureLocation)
	{
		FVector WorldPosition = TextureLocation;
		WorldPosition -= FVector(0.5, 0.5, 0.5);
		WorldPosition *= GetActorScale3D() * 1000;
		WorldPosition += GetActorLocation();
		return WorldPosition;
	}

	int TextureLocationToArrayLocation(FVector TextureLocation)
	{
		FVector Position = TextureLocation;
		Position *= Resolution();
		Position.X = Math::RoundToFloat(Position.X);
		Position.Y = Math::RoundToFloat(Position.Y);
		Position.Z = Math::RoundToFloat(Position.Z);
		return CoordinateToArrayLocation(Math::FloorToInt(Position.X), Math::FloorToInt(Position.Y), Math::FloorToInt(Position.Z));
	}

	int CoordinateToArrayLocation(int x, int y, int z)
	{
		int X = Math::FloorToInt(Math::Clamp(x, 0.0, ResolutionX - 1));
		int Y = Math::FloorToInt(Math::Clamp(y, 0.0, ResolutionY - 1));
		int Z = Math::FloorToInt(Math::Clamp(z, 0.0, ResolutionZ - 1));
		return CoordinateToArrayLocationUnsafe(X, Y, Z);
	}

	int CoordinateToArrayLocationUnsafe(int X, int Y, int Z)
	{
		return (X) + (Y * ResolutionX) + (Z * ResolutionX * ResolutionY);
	}

	void ApplyVolumeDataToMaterial(UMaterialInstanceDynamic mat)
	{
		if(mat == nullptr)
			return;
		mat.SetVectorParameterValue( n"PaintablePlane_Offset", FLinearColor(this.GetActorLocation()));
		mat.SetVectorParameterValue( n"PaintablePlane_Forward", FLinearColor(this.GetActorForwardVector() / (this.GetActorScale3D().X * 1000.0)));
		mat.SetVectorParameterValue( n"PaintablePlane_Right", FLinearColor(this.GetActorRightVector() / (this.GetActorScale3D().Y * 1000.0)));
		mat.SetTextureParameterValue(n"PaintablePlane_PaintTexture2D", PaintTexture2DMaterialOut);
	}

	UFUNCTION()
	void ApplyVolumeDataToMeshComponent(UStaticMeshComponent MeshComp)
	{
		if(MeshComp == nullptr)
			return;

		for (int i = 0; i < MeshComp.Materials.Num(); i++)
		{
			UMaterialInstanceDynamic Material = MeshComp.CreateDynamicMaterialInstance(i);
			ApplyVolumeDataToMaterial(Material);
		}
	}

    UFUNCTION()
	void ApplyVolumeDataToMesh(AStaticMeshActor StaticMesh)
	{
		if(StaticMesh == nullptr)
			return;
		ApplyVolumeDataToMeshComponent(StaticMesh.StaticMeshComponent);
	}

	UFUNCTION()
	void ApplyVolumeDataToMeshes(TArray<AStaticMeshActor> StaticMeshes)
	{
		for (int i = 0; i < StaticMeshes.Num(); i++)
		{
			ApplyVolumeDataToMesh(StaticMeshes[i]);
		}
	}



    UFUNCTION()
	FLinearColor GetColorAtPoint(FVector WorldLocation)
	{
		if(!CPUDataEnabled)
			return FLinearColor(0, 0, 0, 0);

		FVector TextureLocation = WorldLocationToTextureLocation(WorldLocation);
		int Index = TextureLocationToArrayLocation(TextureLocation);
		FLinearColor Result = CPUSideData[Index];
		return Result;
	}

    UFUNCTION()
	void SetColorAtPoint(FVector WorldLocation, FLinearColor Color)
	{
		if(!CPUDataEnabled)
			return;

		FVector TextureLocation = WorldLocationToTextureLocation(WorldLocation);
		int Index = TextureLocationToArrayLocation(TextureLocation);
		CPUSideData[Index] = Color;
	}

	FLinearColor ToColor(FVector v)
	{
		return FLinearColor(v.X, v.Y, v.Z, 1.0);
	}

	// ~20 µs at 12x12x12 on workstation computer. (random bounds, locations and colors.)
	// Likely safe to call multiple times per frame, just not hundreads of times per frame.
	UFUNCTION()
	void SetColorInBox(FVector WorldLocation, FVector WorldBounds, FLinearColor Color)
	{
		if(!CPUDataEnabled && !GPUDataEnabled)
			return;
		
		FVector NewRes = FVector(Math::Max(ResolutionX - 1, 1), Math::Max(ResolutionY - 1, 1), Math::Max(ResolutionZ - 1, 1));
		FVector IndexBounds = WorldSizeToTextureSize(WorldBounds) * NewRes;
		FVector TexturePos = WorldLocationToTextureLocation(WorldLocation) * NewRes;

		if(PlaneType == EPaintablePlaneType::Plane)
			IndexBounds.Z = 9999999.0;

		FVector Start = TexturePos - IndexBounds;
		FVector End   = TexturePos + IndexBounds;
		
		// Casting to int here is fine because it's never negative, so it has the same effect as ceil
		int StartX 	= int(Start.X 	+ 1);
		int StartY 	= int(Start.Y 	+ 1);
		int StartZ 	= int(Start.Z 	+ 1);
		int EndX 	= int(End.X 	+ 1);
		int EndY 	= int(End.Y 	+ 1);
		int EndZ 	= int(End.Z 	+ 1);

		StartX 	= Math::Clamp(StartX,	0, ResolutionX);
		StartY 	= Math::Clamp(StartY,	0, ResolutionY);
		StartZ 	= Math::Clamp(StartZ,	0, ResolutionZ);
		EndX 	= Math::Clamp(EndX, 	0, ResolutionX);
		EndY 	= Math::Clamp(EndY, 	0, ResolutionY);
		EndZ 	= Math::Clamp(EndZ, 	0, ResolutionZ);
		
		if(PlaneType == EPaintablePlaneType::Plane)
		{
			StartZ = 0;
			EndZ = 1;
		}

		if(CPUDataEnabled)
		{
			for (int x = StartX; x < EndX; x++)
			{
				for (int y = StartY; y < EndY; y++)
				{
					for (int z = StartZ; z < EndZ; z++)
					{
						CPUSideData[CoordinateToArrayLocationUnsafe(x, y, z)] = Color;
					}
				}
			}
		}

		if(GPUDataEnabled)
		{
			if(PlaneType == EPaintablePlaneType::Plane)
			{
				// Swap
				if(PaintTexture2D == PaintTexture2DTarget1)
				{
					PaintTexture2D = PaintTexture2DTarget2;
					PaintTexture2DLastFrame = PaintTexture2DTarget1;
				}
				else
				{
					PaintTexture2D = PaintTexture2DTarget1;
					PaintTexture2DLastFrame = PaintTexture2DTarget2;
				}
				
				// Setup
				DrawBox2DMaterialDynamic.SetVectorParameterValue(n"Start", ToColor(FVector(StartX, StartY, StartZ)));
				DrawBox2DMaterialDynamic.SetVectorParameterValue(n"End", ToColor((FVector(EndX, EndY, EndZ)) - FVector::OneVector));
				DrawBox2DMaterialDynamic.SetVectorParameterValue(n"Color", Color);
				DrawBox2DMaterialDynamic.SetVectorParameterValue(n"Resolution", FLinearColor(ResolutionX, ResolutionY, ResolutionZ, 0.0));
				DrawBox2DMaterialDynamic.SetTextureParameterValue(n"LastFrame", PaintTexture2DLastFrame);

				// Draw
				Rendering::DrawMaterialToRenderTarget(PaintTexture2D, DrawBox2DMaterialDynamic);

				// Copy to output texture.
				CopyTexture2DMaterialDynamic.SetTextureParameterValue(n"InputTexture", PaintTexture2D);
				Rendering::DrawMaterialToRenderTarget(PaintTexture2DMaterialOut, CopyTexture2DMaterialDynamic);
			}
			else
			{
				//UPaintableVolume::DrawBox(PaintTextureVolume, FVector(StartX, StartY, StartZ), (FVector(EndX, EndY, EndZ)) - FVector::OneVector, Color);
			}
		}
	}

	UFUNCTION()
	void Clear(FLinearColor Color)
	{
		if(CPUDataEnabled)
		{
			for (int i = 0; i < CPUSideData.Num(); i++)
			{
				CPUSideData[i] = Color;
			}
		}

		if(GPUDataEnabled)
		{
			Rendering::ClearRenderTarget2D(PaintTexture2DTarget1, Color);
			Rendering::ClearRenderTarget2D(PaintTexture2DTarget1, Color);
		}
		//UPaintableVolume::DrawBox(PaintTextureVolume, FVector::ZeroVector, Resolution(), Color);
	}

	// Painting & Readback
	// GetColorAtPoint
	// GetColorsInSphere
	// GetColorsInBox
	
	// SetColorAtPoint
	// SetColorInSphere
	// SetColorInSphere
	
	void Initialize()
	{
		if(ResolutionX < 1)
			ResolutionX = 1;
		if(ResolutionY < 1)
			ResolutionY = 1;
		if(ResolutionZ < 1)
			ResolutionZ = 1;

		CPUSideData = TArray<FLinearColor>();

		if(PlaneType == EPaintablePlaneType::Plane)
		{
			if(CPUDataEnabled)
			{
				CPUSideData.SetNum(ResolutionX * ResolutionY);
			}

			if(GPUDataEnabled)
			{
				PaintTexture2DTarget1 		= Rendering::CreateRenderTarget2D(ResolutionX, ResolutionY, ETextureRenderTargetFormat::RTF_RGBA16f, FLinearColor(0, 0, 0, 0));
				PaintTexture2DTarget2 		= Rendering::CreateRenderTarget2D(ResolutionX, ResolutionY, ETextureRenderTargetFormat::RTF_RGBA16f, FLinearColor(0, 0, 0, 0));
				PaintTexture2DMaterialOut 	= Rendering::CreateRenderTarget2D(ResolutionX, ResolutionY, ETextureRenderTargetFormat::RTF_RGBA16f, FLinearColor(0, 0, 0, 0));
					
				PreviewMesh.SetRelativeScale3D(FVector(10, 10, 0.01));
				PaintTexture2D = PaintTexture2DTarget1;

				DrawBox2DMaterialDynamic = Material::CreateDynamicMaterialInstance(this, DrawBox2DMaterial);

				CopyTexture2DMaterialDynamic = Material::CreateDynamicMaterialInstance(this, CopyTexture2DMaterial);
			}
		}
		else
		{
			if(CPUDataEnabled)
			{
				CPUSideData.SetNum(ResolutionX * ResolutionY * ResolutionZ);
			}
			
			if(GPUDataEnabled)
			{
				// RTF_RGBA32 was broken on PS5, so this uses 16f for now.
				PaintTextureVolume = Rendering::CreateRenderTargetVolume(
					ResolutionX,
					ResolutionY,
					ResolutionZ, ETextureRenderTargetFormat::RTF_RGBA16f, FLinearColor(0, 0, 0, 0));
			}
			PreviewMesh.SetRelativeScale3D(FVector(10, 10, 10));
		}
		
		PreviewMesh.SetStaticMesh(PreviewMeshMesh);
		PreviewMesh.SetHiddenInGame(false);
		PreviewMesh.SetVisibility(PreviewGPUData);
		PreviewMesh.SetMaterial(0, PreviewMaterial);
		UMaterialInstanceDynamic mat = PreviewMesh.CreateDynamicMaterialInstance(0);
		mat.SetTextureParameterValue(n"PaintTextureVolume", PaintTextureVolume);
		mat.SetTextureParameterValue(n"PaintTexture2D", PaintTexture2DMaterialOut);
		if(PlaneType == EPaintablePlaneType::Plane)
		{
			mat.SetVectorParameterValue(n"Resolution", FLinearColor(ResolutionX, ResolutionY, 1, 1));
		}
		else
		{
			mat.SetVectorParameterValue(n"Resolution", FLinearColor(ResolutionX, ResolutionY, ResolutionZ, 1));
		}

		mat.SetScalarParameterValue(n"HazeToggle_IsVolume", (PlaneType == EPaintablePlaneType::Volume) ? 1 : 0);

		//SetActorRotation(FRotator::ZeroRotator);
		
		int pixels = ResolutionX * ResolutionY * ResolutionZ;
		if(PlaneType == EPaintablePlaneType::Plane)
			pixels = ResolutionX * ResolutionY;
		
		if(CPUDataEnabled && pixels > 10000)
		{
			Print("Warning: Paintable Volume " + this.Name + " Has more than 10 000 pixels. Performance could be affected.");
		}
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Initialize();
	}
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		Initialize();
	}

	float GetTime()
	{
		return Time::RealTimeSeconds;
	}

	//UFUNCTION(CallInEditor)
	//void Test()
    //{
	//	SetColorInBox(FVector::ZeroVector, FVector(5000, 5000, 5000), FLinearColor::Red);
	//	SetColorInBox(FVector::ZeroVector, FVector(500, 500, 500), FLinearColor::Green);
	//	return;
	//	
	//	TArray<FVector> RandomPositions = TArray<FVector>();
	//	TArray<FVector> RandomSizes = TArray<FVector>();
	//	TArray<FLinearColor> RandomColors = TArray<FLinearColor>();
	//	int count = 100000;
	//	for (int i = 0; i < count; i++)
	//	{
	//		RandomPositions.Add(FVector(Math::RandRange(-1000, 1000), Math::RandRange(-1000, 1000), Math::RandRange(-1000, 1000)));
	//		RandomSizes.Add(FVector(Math::RandRange(0, 1000), Math::RandRange(0, 1000), Math::RandRange(0, 1000)));
	//		RandomColors.Add(FLinearColor::MakeRandomColor());
	//	}
	//
	//	float Start = GetTime();
	//	for (int i = 0; i < count; i++)
	//	{
	//		SetColorInBox(RandomPositions[i], RandomSizes[i], RandomColors[i]);
	//	}
	//	float End = GetTime();
	//
	//	float milliseconds = (End - Start) * 1000;
	//	float MillisecondsPerThing = (milliseconds / count);
	//	float MicrosecondsPerThing = (milliseconds / count) * 1000;
	//	float ThingsPerMillisecond = 1.0 / MillisecondsPerThing;
	//
	//	Print("ThingsPerMillisecond: " + ThingsPerMillisecond);
	//	Print("MicrosecondsPerThing: " + MicrosecondsPerThing);
	//}

	// Samples 10x10 points of the CPU-side data and draws it as debug points.
	//UFUNCTION()
	//void TestPosition(FVector pos)
	//{
	//	float SampleRegionSize = 250;
	//	int SampleSideCount = 10;
	//	for (int x = 0; x < SampleSideCount; x++)
	//	{
	//		for (int y = 0; y < SampleSideCount; y++)
	//		{
	//			FVector SamplePos = pos + ((FVector(x, y, 0)/SampleSideCount) * SampleRegionSize) - FVector(1,1,0) * SampleRegionSize * 0.5;
	//			FLinearColor result = GetColorAtPoint(SamplePos);
	//			DrawPoint(SamplePos, 10, result);
	//		}
	//	}
	//}
	
	float GetOffset(float a, float b)
	{
		if(b == 0)
			return 0;
		else
			return (a / b) - 0.5;
	}
	FVector GetOffset(FVector a, FVector b)
	{
		return FVector(
			GetOffset(a.X, b.X),
			GetOffset(a.Y, b.Y),
			GetOffset(a.Z, b.Z));
	}
	
    //UFUNCTION(BlueprintEvent)
	//void DrawPoint(FVector Position, float Size, FLinearColor PointColor, float Duration = 0)
	//{
//
	//}
	
    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		PreviewMesh.SetVisibility(PreviewGPUData);
		if(PreviewCPUData)
		{
			int x = 0;
			int y = 0;
			int z = 0;

			int pixels = ResolutionX * ResolutionY * ResolutionZ;
			if(PlaneType == EPaintablePlaneType::Plane)
				pixels = ResolutionX * ResolutionY;

			for (int i = 0; i < pixels; i++)
			{
				FVector Location = GetOffset(FVector(x, y, z), Resolution() - FVector(1));
				if(PlaneType == EPaintablePlaneType::Plane)
					Location += FVector::UpVector * GetActorScale3D().Z * 0.5;
				
				FVector Multiplier = FVector(1,1,1);
				if(PlaneType == EPaintablePlaneType::Plane)
				{
				 	Multiplier = FVector(1,1,0);
				}
				FVector WorldPos = GetActorTransform().TransformPosition(Location * Multiplier * 1000);
				//DrawPoint(GetActorLocation() + (Location * 1000 * this.ActorTransform.Scale3D * Multiplier), 10, CPUSideData[i]);
				//DrawPoint(WorldPos, 10, CPUSideData[i]);
				
				x++;
				if(x >= ResolutionX)
				{
					x = 0;
					y++;
					if(y >= ResolutionY)
					{
						y = 0;
						z++;
					}
				}
			}
		}
	}
}