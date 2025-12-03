enum EPigSiloPlatformSpiralBuilderRotationDirection
{
	CounterClockwise = 0,
	ClockWise
}

enum EPigSiloPlatformSpiralBuilderVerticalDirection
{
	Descending = 0,
	Ascending
}

USTRUCT()
struct FPigSiloSplineBuilder
{
	UPROPERTY()
	float Radius = 500.0;

	UPROPERTY()
	int PointCount = 10;

	UPROPERTY()
	float ArcDegrees = 720.0;

	UPROPERTY()
	float Height = 1000.0;

	UPROPERTY()
	EPigSiloPlatformSpiralBuilderRotationDirection RotationDirection = EPigSiloPlatformSpiralBuilderRotationDirection::CounterClockwise;

	UPROPERTY()
	EPigSiloPlatformSpiralBuilderVerticalDirection VerticalDirection = EPigSiloPlatformSpiralBuilderVerticalDirection::Descending;
}

class APigSiloPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;


	UPROPERTY(Category = "Spline")
	UStaticMesh Mesh;

	UPROPERTY(Category = "Spline")
	UMaterialInstance Material;

	UPROPERTY(Category = "Spline")
	ESplineMeshAxis MeshForwardAxis = ESplineMeshAxis::X;

	UPROPERTY(Category = "Spline")
	float SegmentSize = 100.0;

	UPROPERTY(Category = "Spline")
	float WidthMultiplier = 1.0;

	UPROPERTY(Category = "Spline")
	FPigSiloSplineBuilder SpiralBuilder;


	UPROPERTY(Category = "Obstacles")
	FHazeRange DistanceBetweenObstacles(1500, 3000);

	UPROPERTY(Category = "Obstacles")
	TArray<TSubclassOf<APigSiloObstacle>> ObstacleClasses;


	UPROPERTY(EditAnywhere)
	bool bGenerateSplineMeshes = true;

	UPROPERTY(VisibleAnywhere, Category = "Obstacles")
	TArray<APigSiloObstacle> GeneratedObstacles;


#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
	default Billboard.SpriteName = "T_Loft_Spline";
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BuildSpiral();

		if (bGenerateSplineMeshes)
			BuildSplineMeshes();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void StartSiloMovement()
	{
		for (auto Player : Game::Players)
		{
			auto PlayerSiloComponent = UPlayerPigSiloComponent::Get(Player);
			PlayerSiloComponent.Start(this);
		}
	}

	float GetHorizontalOffsetForPlayer(AHazePlayerCharacter Player) const
	{
		const float Offset = 100;
		return Player.IsMio() ? -Offset : Offset;
	}

	// Shamelessly stolen from HazeSplineDetails
	private void BuildSpiral()
	{
		TArray<FHazeSplinePoint> Points;

		float Angle = 0.0;
		float AngleIncrement = (Math::DegreesToRadians(SpiralBuilder.ArcDegrees) / SpiralBuilder.PointCount);

		float Height = 0.0;
		float HeightIncrement = SpiralBuilder.Height / (SpiralBuilder.PointCount - 1);

		FVector Origin;
		FQuat CircleRotation;

		for (int i = 0; i < SpiralBuilder.PointCount; ++i)
		{
			const float Radius = SpiralBuilder.Radius;

			FHazeSplinePoint Point;
			Point.RelativeLocation = Origin;

			FVector RelativePos = FVector(Math::Sin(-Angle) * Radius, Math::Cos(Angle) * Radius, Height);
			Point.RelativeLocation += CircleRotation.RotateVector(RelativePos);
			Points.Add(Point);

			if (SpiralBuilder.RotationDirection == EPigSiloPlatformSpiralBuilderRotationDirection::ClockWise)
				Angle += AngleIncrement;
			else
				Angle -= AngleIncrement;

			if (SpiralBuilder.VerticalDirection == EPigSiloPlatformSpiralBuilderVerticalDirection::Ascending)
				Height += HeightIncrement;
			else
				Height -= HeightIncrement;
		}

		Spline.SplineSettings.bClosedLoop = false;
		Spline.SplinePoints = Points;
	}

	private void BuildSplineMeshes()
	{
		float MeshYSize = Mesh.BoundingBox.Extent.Y;
		float MeshYScale = (Mesh.BoundingBox.Extent.X / MeshYSize);

		for (float DistanceAlongSpline = 0.0, i = 0; DistanceAlongSpline <= Spline.GetSplineLength(); DistanceAlongSpline += SegmentSize, i++)
		{
			// Create spline mesh
			USplineMeshComponent SplineMesh = USplineMeshComponent::GetOrCreate(this, FName("SplineMesh_" + i));
			SplineMesh.SetStaticMesh(Mesh);
			SplineMesh.SetCollisionProfileName(n"BlockAllDynamic");
			SplineMesh.SetCollisionObjectType(ECollisionChannel::ECC_WorldDynamic);
			SplineMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			SplineMesh.SetForwardAxis(MeshForwardAxis, false);

			SplineMesh.SetMaterial(0, Material);
			SplineMesh.AddTag(PigTags::PigSlide);

			SplineMesh.SetCastShadow(false);

			float SegmentEnd = Math::Min(DistanceAlongSpline + SegmentSize, Spline.GetSplineLength());

			FTransform StartTransform = Spline.GetRelativeTransformAtSplineDistance(DistanceAlongSpline);
			FTransform EndTransform = Spline.GetRelativeTransformAtSplineDistance(SegmentEnd);

			float TangentSize = SegmentEnd - DistanceAlongSpline;
			FVector StartTangent = Spline.GetRelativeTangentAtSplineDistance(DistanceAlongSpline).GetSafeNormal() * TangentSize;
			FVector EndTangent = Spline.GetRelativeTangentAtSplineDistance(SegmentEnd).GetSafeNormal() * TangentSize;

			SplineMesh.SetStartAndEnd(StartTransform.Location, StartTangent, EndTransform.Location, EndTangent, false);
			SplineMesh.SetSmoothInterpRollScale(true, false);

			SplineMesh.SetStartScale(FVector2D(StartTransform.Scale3D.Y * MeshYScale * WidthMultiplier, StartTransform.Scale3D.Z), bUpdateMesh = false);
			SplineMesh.SetEndScale(FVector2D(EndTransform.Scale3D.Y * MeshYScale * WidthMultiplier, EndTransform.Scale3D.Z), bUpdateMesh = false);

			SplineMesh.SetStartRoll(Math::DegreesToRadians(StartTransform.Rotator().Roll), bUpdateMesh = false);
			SplineMesh.SetEndRoll(Math::DegreesToRadians(EndTransform.Rotator().Roll), bUpdateMesh = false);

			SplineMesh.SetForwardAxis(MeshForwardAxis, bUpdateMesh = false);
			SplineMesh.UpdateMesh();
		}
	}

	UFUNCTION(CallInEditor)
	private void GenerateObstacles()
	{
		for (auto Actor : GeneratedObstacles)
			Actor.DestroyActor();
		GeneratedObstacles.Reset();

		for (float DistanceAlongSpline = 1000; DistanceAlongSpline < Spline.SplineLength; DistanceAlongSpline += GetNextSplineDistanceIncrement())
		{
			CreateRandomObstacleAtSplineDistance(DistanceAlongSpline);
		}
	}

	private float GetNextSplineDistanceIncrement() const
	{
		return Math::RandRange(800,2000);
	}

	private void CreateRandomObstacleAtSplineDistance(float DistanceAlongSpline)
	{
		int Index = Math::RandRange(0, ObstacleClasses.Num() - 1);

		FVector Location = Spline.GetWorldLocationAtSplineDistance(DistanceAlongSpline);
		FQuat Rotation = FQuat::MakeFromX(Spline.GetWorldForwardVectorAtSplineDistance(DistanceAlongSpline).ConstrainToPlane(FVector::UpVector));

		APigSiloObstacle Obstacle = SpawnActor(ObstacleClasses[Index], Location, Rotation.Rotator());
		Obstacle.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		GeneratedObstacles.Add(Obstacle);
	}
}