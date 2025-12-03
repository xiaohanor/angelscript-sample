
class ATangentBaker : AHazeActor
{
    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif

    UPROPERTY(DefaultComponent)
	USceneCaptureComponent2D CaptureComp;
	default CaptureComp.OrthoWidth = 100;
	default CaptureComp.ProjectionType = ECameraProjectionMode::Orthographic;
	default CaptureComp.CompositeMode = ESceneCaptureCompositeMode::SCCM_Composite;

    UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Tangents;

    UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Normals;

    UPROPERTY(EditAnywhere)
	UMaterialInterface TangentBakerMaterial;

    UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComponent;

    UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;
		

	void DrawSceneWithPadding()
	{
		float pixelSize = (100.0f / Tangents.SizeX);
		for (int i = 0; i < 4; i++) 
		{
			int j = i-3;
			MeshComponent.SetRelativeLocation(FVector(0, pixelSize, 0) * j);
			CaptureComp.CaptureScene();
			MeshComponent.SetRelativeLocation(FVector(0, -pixelSize, 0) * j);
			CaptureComp.CaptureScene();
			MeshComponent.SetRelativeLocation(FVector(0, 0, pixelSize) * j);
			CaptureComp.CaptureScene();
			MeshComponent.SetRelativeLocation(FVector(0, 0, -pixelSize) * j);
			CaptureComp.CaptureScene();
		}
		MeshComponent.SetRelativeLocation(FVector(0, 0, 0));
		CaptureComp.CaptureScene();
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		CaptureComp.bCaptureEveryFrame = false;
		CaptureComp.bCaptureOnMovement = false;
		if(Mesh == nullptr)
			return;

		MeshComponent.SetStaticMesh(Mesh);
		for (int i = 0; i < MeshComponent.Materials.Num(); i++) 
		{
			MeshComponent.SetMaterial(i, TangentBakerMaterial);
		}

		CaptureComp.PrimitiveRenderMode = ESceneCapturePrimitiveRenderMode::PRM_UseShowOnlyList;
		CaptureComp.ShowOnlyActors.Empty();
		CaptureComp.ShowOnlyActors.Add(this);


		Rendering::ClearRenderTarget2D(Tangents);
		Rendering::ClearRenderTarget2D(Normals);
		
		MeshComponent.SetScalarParameterValueOnMaterials(n"BakeNormals", 0);
		CaptureComp.TextureTarget = Tangents;
		DrawSceneWithPadding();

		Rendering::ClearRenderTarget2D(Normals);
		MeshComponent.SetScalarParameterValueOnMaterials(n"BakeNormals", 1);
		CaptureComp.TextureTarget = Normals;
		DrawSceneWithPadding();
    }

	UFUNCTION(CallInEditor)
	void Capture()
	{
	}
}