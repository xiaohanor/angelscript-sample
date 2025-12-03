UCLASS(Abstract)
class ASketchbookCloud : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent CloudRoot1;

	UPROPERTY(DefaultComponent)
	USceneComponent CloudRoot2;

	UPROPERTY(DefaultComponent)
	USceneComponent CloudRoot3;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent OriginalCloud;

	UPROPERTY(EditDefaultsOnly)
	TArray<UTexture2D> Textures;

	UPROPERTY(EditAnywhere)
	FHazeRange RandomSize;

	UPROPERTY(EditAnywhere)
	int NumClouds = 15;

	UPROPERTY(EditAnywhere)
	int MinDistance = 10000;

	UPROPERTY(EditAnywhere)
	float MaxHeight = 25;

	UPROPERTY()
	TArray<UMaterialInstanceDynamic> DynamicMaterials;

	UPROPERTY(EditAnywhere)
	ASketchbookSun Sun;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		UpdateMaterials();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpdateMaterials();
	}

	void UpdateMaterials()
	{
		DynamicMaterials.SetNumZeroed(Textures.Num());
		for (int i = 0; i < Textures.Num(); i++)
		{
			auto Material = Material::CreateDynamicMaterialInstance(this, OriginalCloud.GetMaterial(0));
			if (Material != nullptr)
			{
				Material.SetTextureParameterValue(n"Texture", Textures[i]);
				DynamicMaterials[i] = Material;
			}
		}

		TArray<UStaticMeshComponent> Clouds;
		GetComponentsByClass(UStaticMeshComponent, Clouds);
		for (int i = 0; i < Clouds.Num(); i++)
		{
			auto Cloud = Clouds[i];
			if (Cloud != OriginalCloud)
			{
				auto RndMaterialIndex = Math::WrapIndex(i, 0, DynamicMaterials.Num());
				Cloud.SetMaterial(0, DynamicMaterials[RndMaterialIndex]);
			}
		}
	}

	UFUNCTION(BlueprintCallable, CallInEditor)
	void Generate()
	{
		TArray<UStaticMeshComponent> Clouds;
		GetComponentsByClass(UStaticMeshComponent, Clouds);
		for (UStaticMeshComponent Cloud : Clouds)
		{
			if (Cloud != OriginalCloud)
			{
				Cloud.DestroyComponent(this);
			}
		}

		FTransform RandomRotationT = Root.WorldTransform;

		TArray<USceneComponent> Roots;
		Roots.Add(CloudRoot1);
		Roots.Add(CloudRoot2);
		Roots.Add(CloudRoot3);

		TArray<FVector> CloudPositions;
		CloudPositions.SetNumZeroed(NumClouds);
		for (int i = 0; i < NumClouds; i++)
		{
			auto Cloud = UStaticMeshComponent::Create(this);

			const int RootIndex = Math::RandRange(0, Roots.Num() - 1);
			Cloud.AttachToComponent(Roots[RootIndex]);

			Cloud.StaticMesh = OriginalCloud.StaticMesh;

			Cloud.SetRenderCustomDepth(true);
			Cloud.SetCustomDepthStencilValue(60);

			for (int y = 0; y < 100; y++)
			{
				RandomRotationT.SetRotation(FRotator(Math::RandRange(0, MaxHeight), Math::RandRange(-180, 180), 0));
				Cloud.SetWorldTransform(OriginalCloud.RelativeTransform * RandomRotationT);

				bool bValidPos = true;
				for (FVector Pos : CloudPositions)
				{
					if ((Pos - Cloud.RelativeLocation).Size() < MinDistance)
					{
						bValidPos = false;
						break;
					}
				}

				if (bValidPos)
				{
					CloudPositions[i] = Cloud.RelativeLocation;
					break;
				}
			}

			Cloud.SetWorldScale3D(Cloud.RelativeScale3D * RandomSize.Rand());
		}

		UpdateMaterials();
	}

	float UpdateSunPos = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CloudRoot1.SetWorldRotation(CloudRoot1.WorldRotation + FRotator(0, 0.3 * DeltaSeconds, 0));
		CloudRoot2.SetWorldRotation(CloudRoot2.WorldRotation + FRotator(0, 0.6 * DeltaSeconds, 0));
		CloudRoot3.SetWorldRotation(CloudRoot3.WorldRotation + FRotator(0, 0.1 * DeltaSeconds, 0));

		UpdateSunPos -= DeltaSeconds;
		if (UpdateSunPos < 0 && Sun != nullptr)
		{
			for (auto Material : DynamicMaterials)
			{
				Material.SetVectorParameterValue(n"SunPos", FLinearColor(Sun.Sun.WorldLocation));
			}
			UpdateSunPos = 1;
		}
	}
};
