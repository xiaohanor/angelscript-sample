UCLASS(Abstract)
class ASketchbookColorizeActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshUnColorized;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshColorized;

	float ColorRatio = 0;
	bool bColorize = false;
	float ColorizeBlendTime = 0;


	float TotalPaintPoints;
	float PaintPoints;
	UPROPERTY(EditAnywhere)
	float PaintPointCompleationRate = 1;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshUnColorized.StaticMesh = MeshColorized.StaticMesh;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshColorized.SetVisibility(false);

		ActorTickEnabled = false;
		SetColorRatio(0);

		// Colorize(5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bColorize)
		{
			ColorRatio += DeltaSeconds / ColorizeBlendTime;
			ColorRatio = Math::Clamp(ColorRatio, 0.0, 1.0);

			// if (ColorRatio > 0.95)
			// 	ColorRatio = 0.05;

			SetColorRatio(ColorRatio);

			if (ColorRatio >= 1)
			{
				bColorize = false;
				MeshUnColorized.SetVisibility(false);
				ActorTickEnabled = false;
			}
		}
	}

	void SetColorRatio(float Value)
	{
		MeshUnColorized.SetScalarParameterValueOnMaterials(n"ColorRatio", Value);
		MeshColorized.SetScalarParameterValueOnMaterials(n"ColorRatio", Value);
	}

	UFUNCTION()
	void Colorize(float BlendTime = 5)
	{
		MeshColorized.SetVisibility(true);

		ColorizeBlendTime = BlendTime;
		bColorize = true;
		ActorTickEnabled = true;
	}

	UFUNCTION()
	void AddTotalPaintPoint()
	{
		TotalPaintPoints++;
	}

	UFUNCTION()
	void AddPaintPoints()
	{
		PaintPoints++;
		if(TotalPaintPoints*PaintPointCompleationRate <= PaintPoints)
		{
			Print("YOUWIN");
		}
	}
};
