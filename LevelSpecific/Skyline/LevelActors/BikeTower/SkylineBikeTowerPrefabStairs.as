class ASkylineBikeTowerPrefabStairs : ASkylineBikeTowerPrefab
{
	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;

//	UPROPERTY(EditAnywhere)
//	float StepSpan = 0.5;

	UPROPERTY(EditAnywhere)
	FVector2D StepSpan = FVector2D(0.5, 0.5);

	UPROPERTY(EditAnywhere)
	int Steps = 16;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Mesh == nullptr)
			return;

		for (int i = 0; i < Steps; i++)
		{
			auto MeshComp = UStaticMeshComponent::Create(this, FName("Step_" + i));
			MeshComp.StaticMesh = Mesh;
			MeshComp.SetMaterial(0, Material);
			MeshComp.RelativeLocation = FVector(0.0, 0.0, i * 100.0 * (1.0 / Steps));
	//		MeshComp.RelativeLocation = FVector((1.0 / Steps) * i * 50.0, 0.0, i * 100.0 * (1.0 / Steps));
//			float Scale = 1.0 - (StepSpan / Steps) * i;
			MeshComp.RelativeScale3D = FVector(1.0 - (StepSpan.X / Steps) * i,
											   1.0 - (StepSpan.Y / Steps) * i,
											   (1.0 / Steps));
		
			Primitives.Add(MeshComp);
		}

		Super::ConstructionScript();
	}
};