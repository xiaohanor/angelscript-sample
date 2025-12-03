
struct FLineCritter
{
	UPROPERTY()
	UStaticMeshComponent MeshComp;

	UPROPERTY()
	float Location;
}

class ACritterLine : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 4000.0;

    UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;
	
    UPROPERTY(EditAnywhere)
	int AntCount = 10;

    UPROPERTY(EditAnywhere)
	float AntMoveSpeed = 250;

    UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

    UPROPERTY()
	float AntSpacing = 0;
	
    UPROPERTY()
	TArray<FLineCritter> AntPool;

	//UPROPERTY()
	//UAkAudioEvent SquashAudioEvent;

	float StartAnimateSpeed = 0;
	float DefaultMoveSpeed = 250;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		for (int i = 0; i < ConstructionScriptTempMeshes.Num(); i++)
		{
			if(ConstructionScriptTempMeshes[i] != nullptr)
				ConstructionScriptTempMeshes[i].DestroyComponent(ConstructionScriptTempMeshes[i]);
		}
		AntPool.Empty();
		ConstructionScriptTempMeshes.Empty();
		
		if(Mesh == nullptr)
			return;

		if(AntCount == 0)
			return;
			
		for (int i = 0; i < AntCount; i++)
		{
			float t = (float(i) / float(AntCount - 1.0f)) * Spline.SplineLength;
			UStaticMeshComponent NewMesh = CreateComponent(UStaticMeshComponent);
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";
			NewMesh.SetWorldTransform(Spline.GetWorldTransformAtSplineDistance(t));

			FLineCritter NewAnt = FLineCritter();
			NewAnt.MeshComp = NewMesh;
			NewAnt.Location = t;
			AntPool.Add(NewAnt);
			auto mat = NewMesh.CreateDynamicMaterialInstance(0);
			StartAnimateSpeed = mat.GetScalarParameterValue(n"Blend1AnimateSpeed");
			NewMesh.SetScalarParameterValueOnMaterials(n"Blend1AnimateSpeed", StartAnimateSpeed * (AntMoveSpeed / DefaultMoveSpeed));
		}

		AntSpacing = Spline.SplineLength / AntCount;
	}

    UPROPERTY()
	TArray<UStaticMeshComponent> ConstructionScriptTempMeshes;

	// Do this on construction so the artists can see it.
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		//Super::ConstructionScript();
		if(Mesh == nullptr)
			return;
		
		if(AntCount == 0)
			return;
			
		ConstructionScriptTempMeshes.Empty();
		for (int i = 0; i < AntCount; i++)
		{
			float t = (float(i) / float(AntCount - 1.0f)) * Spline.SplineLength;
			UStaticMeshComponent NewMesh = CreateComponent(UStaticMeshComponent);
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";
			NewMesh.bIsEditorOnly = true;
			NewMesh.SetWorldTransform(Spline.GetWorldTransformAtSplineDistance(t));
			ConstructionScriptTempMeshes.Add(NewMesh);
		}
    }
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Mesh == nullptr)
			return;

		if(AntCount == 0)
			return;
		
		if(AntPool.Num() <= 0)
			return;

		for (int i = 0; i < AntCount; i++)
		{
			if(AntPool[i].MeshComp == nullptr)
				continue;

			AntPool[i].MeshComp.SetWorldTransform(Spline.GetWorldTransformAtSplineDistance(AntPool[i].Location));

			AntPool[i].Location += DeltaTime * AntMoveSpeed;
			
			// wrapping around.
			if(AntPool[i].Location > Spline.SplineLength)
			{
				AntPool[i].Location = 0;
			}
		}
    }
}