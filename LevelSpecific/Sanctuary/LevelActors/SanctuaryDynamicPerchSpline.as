class UMovableSplineMeshComponent : USplineMeshComponent
{
	default Mobility = EComponentMobility::Movable;
}

class ASanctuaryDynamicPerchSpline : APerchSpline
{
	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;

	TArray<USplineMeshComponent> SplineMeshComponents;

	UPROPERTY(EditAnywhere)
	float DesiredMeshLength = 300.0;

	UPROPERTY(EditAnywhere)
	float MeshScale = 1.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
#if EDITOR
//		SplineMeshComponents.Reset();
//		UpdateSplineMeshes();
#endif	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		UpdateSplineMeshes();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	//	DrawDebug();

//		auto& LastPoint = Spline.SplinePoints.Last();

//		LastPoint.RelativeLocation += FVector::RightVector * 100.0 * DeltaSeconds;

		Spline.UpdateSpline();

		UpdateSplineMeshes();
	}

	void UpdateSplineMeshes()
	{
		float NumOfMeshes;
		float ShortMeshLenght = Math::Modf(Spline.SplineLength / DesiredMeshLength, NumOfMeshes) * DesiredMeshLength;

		while (SplineMeshComponents.Num() != int(NumOfMeshes) + 1)
		{
			if (SplineMeshComponents.Num() < int(NumOfMeshes) + 1)
			{
				auto SplineMesh = UMovableSplineMeshComponent::Create(this);
				SplineMesh.AttachToComponent(Spline);
				SplineMesh.StaticMesh = Mesh;
				for (int i = 0; i < SplineMesh.NumMaterials; i++)
					SplineMesh.SetMaterial(i, Material);
				SplineMeshComponents.Add(SplineMesh);
			}
			else
			{
				SplineMeshComponents.Last().DestroyComponent(this);
				SplineMeshComponents.RemoveAt(SplineMeshComponents.Num() - 1);
			}
		}

//		PrintToScreen("NumOfMeshes: " + SplineMeshComponents.Num(), 0.0, FLinearColor::Green);
//		PrintToScreen("ShortMeshLenght: " + ShortMeshLenght, 0.0, FLinearColor::Green);

		for (int i = 0; i < SplineMeshComponents.Num(); i++)
		{
			float MeshLength = (i == SplineMeshComponents.Num() ? ShortMeshLenght : DesiredMeshLength);

			auto StartPosition = Spline.GetSplinePositionAtSplineDistance(Spline.SplineLength - ((i + 1) * MeshLength));
			auto EndPosition = Spline.GetSplinePositionAtSplineDistance(Spline.SplineLength - (i * MeshLength));

			SplineMeshComponents[i].SetStartAndEnd(			
				StartPosition.RelativeLocation,
				StartPosition.RelativeTangent.GetSafeNormal() * MeshLength,
				EndPosition.RelativeLocation,
				EndPosition.RelativeTangent.GetSafeNormal() * MeshLength,
				true				
			);

			SplineMeshComponents[i].SetStartScale(FVector2D(MeshScale, MeshScale));			
			SplineMeshComponents[i].SetEndScale(FVector2D(MeshScale, MeshScale));			

//			SplineMeshComponents[i].SetSplineUpDir(StartPosition.WorldUpVector);

//			Debug::DrawDebugLine(StartPosition.WorldLocation, StartPosition.WorldLocation + StartPosition.WorldTangent * 1.0, FLinearColor::Green, 5.0, 0.0);
//			Debug::DrawDebugLine(EndPosition.WorldLocation, EndPosition.WorldLocation + EndPosition.WorldTangent * 1.0, FLinearColor::Red, 5.0, 0.0);
//			Debug::DrawDebugPoint(StartPosition.WorldLocation, 50.0, FLinearColor::Red, 0.0);
//			Debug::DrawDebugPoint(EndPosition.WorldLocation, 50.0, FLinearColor::Red, 0.0);
		}
	}

	void DrawDebug()
	{
		float SegmentLenght = 50.0;

		int Segments = Math::FloorToInt(Spline.SplineLength / SegmentLenght);

		SegmentLenght = Spline.SplineLength / Segments;

		for (int i = 0; i <= Segments; i++)
		{
			FVector LineStart;
			FVector LineEnd;

			LineStart = Spline.GetWorldLocationAtSplineDistance(i * SegmentLenght);
			LineEnd = Spline.GetWorldLocationAtSplineDistance((i + 1) * SegmentLenght);
			Debug::DrawDebugLine(LineStart, LineEnd, FLinearColor::Yellow, 5.0, 0.0);
		}
	}
}