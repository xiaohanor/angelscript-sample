UCLASS(Abstract)
class ALandscapeVirtualTextureController : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

    UPROPERTY(DefaultComponent)
	URuntimeVirtualTextureComponent ShadingData0;
    UPROPERTY(DefaultComponent)
	URuntimeVirtualTextureComponent ShadingData1;
    UPROPERTY(DefaultComponent)
	URuntimeVirtualTextureComponent ShadingData2;
    UPROPERTY(DefaultComponent)
	URuntimeVirtualTextureComponent ShadingData3;

    UPROPERTY(DefaultComponent)
	URuntimeVirtualTextureComponent HeightData0;
    UPROPERTY(DefaultComponent)
	URuntimeVirtualTextureComponent HeightData1;
    UPROPERTY(DefaultComponent)
	URuntimeVirtualTextureComponent HeightData2;
    UPROPERTY(DefaultComponent)
	URuntimeVirtualTextureComponent HeightData3;
	
	UPROPERTY(EditAnywhere)
	ALandscape TargetLandscape0;
	
	UPROPERTY(EditAnywhere)
	ALandscape TargetLandscape1;
	
	UPROPERTY(EditAnywhere)
	ALandscape TargetLandscape2;
	
	UPROPERTY(EditAnywhere)
	ALandscape TargetLandscape3;

	UPROPERTY()
	bool Isblueprint = false;
	UPROPERTY()
	TArray<ALandscape> TargetLandscapes;

	UPROPERTY()
	TArray<URuntimeVirtualTextureComponent> ShadingDatas;

	UPROPERTY()
	TArray<URuntimeVirtualTextureComponent> HeightDatas;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		this.SetActorScale3D(FVector(1, 1, 1));
		this.SetActorRotation(FRotator(0, 0, 0));
		
		ShadingDatas.Empty();
		ShadingDatas.Add(ShadingData0);
		ShadingDatas.Add(ShadingData1);
		ShadingDatas.Add(ShadingData2);
		ShadingDatas.Add(ShadingData3);

		HeightDatas.Empty();
		HeightDatas.Add(HeightData0);
		HeightDatas.Add(HeightData1);
		HeightDatas.Add(HeightData2);
		HeightDatas.Add(HeightData3);

		TargetLandscapes.Empty();
		TargetLandscapes.Add(TargetLandscape0);
		TargetLandscapes.Add(TargetLandscape1);
		TargetLandscapes.Add(TargetLandscape2);
		TargetLandscapes.Add(TargetLandscape3);

		for (int i = 0; i < 4; i++)
		{
			ALandscape TargetLandscape = TargetLandscapes[i];
			URuntimeVirtualTextureComponent ShadingData = ShadingDatas[i];
			URuntimeVirtualTextureComponent HeightData = HeightDatas[i];
			
			if(TargetLandscape == nullptr)
				continue;

			TargetLandscape.RuntimeVirtualTextures.Empty();
			TargetLandscape.RuntimeVirtualTextures.Add(ShadingData.VirtualTexture);
			TargetLandscape.RuntimeVirtualTextures.Add(HeightData.VirtualTexture);

			FVector TargetLandscapeOrigin;
			FVector TargetLandscapeBounds;
			TargetLandscape.GetActorBounds(false, TargetLandscapeOrigin, TargetLandscapeBounds, false);
			
			ShadingData.SetWorldLocation(TargetLandscapeOrigin - TargetLandscapeBounds * FVector(1, 1, 1));
			HeightData.SetWorldLocation(TargetLandscapeOrigin - (TargetLandscapeBounds * FVector(1, 1, 1)));

			ShadingData.SetWorldScale3D(TargetLandscapeBounds * 2.0);
			HeightData.SetWorldScale3D(TargetLandscapeBounds * 2.0);
		}
    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {

    }

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {

    }
}