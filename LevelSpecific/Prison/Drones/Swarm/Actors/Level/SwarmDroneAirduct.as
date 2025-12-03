class ASwarmDroneAirduct : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;


	// The zone where the player will be sucked (giggity!)
	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor, EditAnywhere)
	USwarmDroneAirductComponent AirductComponent;


	UPROPERTY(DefaultComponent, Attach = Root, EditAnywhere)
	UHazeSplineComponent Spline;


	UPROPERTY(EditAnywhere, Category = "Airduct")
	UStaticMesh AirductMesh;

	UPROPERTY(EditAnywhere, Category = "Airduct")
	float AirudctSegmentSize = 50.0;

	UPROPERTY(EditAnywhere, Category = "Airduct")
	float AirductWidthMultiplier = 0.6;


	UPROPERTY(NotEditable, BlueprintHidden)
	USplineMeshComponent LastSplineMesh = nullptr;


	private bool bActive;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Editor::IsSelected(this))
			Spline.UpdateSpline();

		// Generate spline mesh
		if (AirductMesh == nullptr)
			return;

		float MeshYSize = AirductMesh.BoundingBox.Extent.Y;
		float MeshYScale = (AirductMesh.BoundingBox.Extent.X / MeshYSize);

		int Count = 0;
		for (float DistanceAlongSpline = 0.0; DistanceAlongSpline <= Spline.GetSplineLength(); DistanceAlongSpline += AirudctSegmentSize, Count++)
		{
			// Create spline mesh
			USplineMeshComponent SplineMesh = CreateSplineMeshComponent(Count);

			float SegmentEnd = Math::Min(DistanceAlongSpline + AirudctSegmentSize, Spline.GetSplineLength());

			FTransform StartTransform = Spline.GetRelativeTransformAtSplineDistance(DistanceAlongSpline);
			FTransform EndTransform = Spline.GetRelativeTransformAtSplineDistance(SegmentEnd);

			float TangentSize = SegmentEnd - DistanceAlongSpline;
			FVector StartTangent = Spline.GetRelativeTangentAtSplineDistance(DistanceAlongSpline).GetSafeNormal() * TangentSize;
			FVector EndTangent = Spline.GetRelativeTangentAtSplineDistance(SegmentEnd).GetSafeNormal() * TangentSize;

			SplineMesh.SetStartAndEnd(StartTransform.Location, StartTangent, EndTransform.Location, EndTangent, false);
			SplineMesh.SetSmoothInterpRollScale(true, false);

			SplineMesh.SetStartScale(FVector2D(StartTransform.Scale3D.Y * MeshYScale * AirductWidthMultiplier, StartTransform.Scale3D.Z * AirductWidthMultiplier), bUpdateMesh = false);
			SplineMesh.SetEndScale(FVector2D(EndTransform.Scale3D.Y * MeshYScale * AirductWidthMultiplier, EndTransform.Scale3D.Z * AirductWidthMultiplier), bUpdateMesh = false);

			SplineMesh.SetStartRoll(Math::DegreesToRadians(StartTransform.Rotator().Roll), bUpdateMesh = false);
			SplineMesh.SetEndRoll(Math::DegreesToRadians(EndTransform.Rotator().Roll), bUpdateMesh = false);

			SplineMesh.SetForwardAxis(ESplineMeshAxis::X, bUpdateMesh = false);
			SplineMesh.UpdateMesh();

			LastSplineMesh = SplineMesh;
		}

		// Update exhaust transform
		AirductComponent.ExhaustTransform = Spline.GetRelativeTransformAtSplineDistance(Spline.SplineLength);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AirductComponent.TravelSpline = Spline;
		Activate();
	}

	UFUNCTION()
	void Activate()
	{
		AirductComponent.EnableTrigger(this);
		bActive = true;
	}

	UFUNCTION()
	void Deactivate()
	{
		AirductComponent.DisableTrigger(this);
		bActive = false;
	}

	UFUNCTION()
	bool IsActive() 
	{
		return bActive;
	}

	private USplineMeshComponent CreateSplineMeshComponent(int Id)
	{
		// Get unique name
		FName SplineMeshName = Name;
		SplineMeshName.SetNumber(Id);

		// Create the guy
		USplineMeshComponent SplineMeshComponent = USplineMeshComponent::Create(this, SplineMeshName);
		SplineMeshComponent.SetStaticMesh(AirductMesh);
		SplineMeshComponent.SetCollisionProfileName(n"BlockAllDynamic");
		Editor::Editor_ChangePrimitiveShadowing(SplineMeshComponent, true, false, true);

		return SplineMeshComponent;
	}
}