struct FSplineCorridorColliderTriangle
{
    int Vertex0;
    int Vertex1;
    int Vertex2;
}

class USplineCorridorColliderComponent : UProceduralMeshComponent
{
	default SetCollisionObjectType(ECollisionChannel::ECC_WorldDynamic);
	default SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
    default PrimaryComponentTick.TickGroup = ETickingGroup::TG_HazeGameplay;

	UPROPERTY(EditAnywhere)
	int ResolutionX = 4;
    
	UPROPERTY(EditAnywhere)
	int ResolutionY = 2;

    UPROPERTY(EditAnywhere)
    float SizeX = 1000;

    UPROPERTY(EditAnywhere)
    float SizeY = 1000;

	TArray<FVector> Vertices;
	TArray<FVector> Normals;
	TArray<FSplineCorridorColliderTriangle> Triangles;

    // Empty arrays
	TArray<FVector2D> UV0;
	TArray<FVector2D> UV1;
	TArray<FLinearColor> VertexColors;
	TArray<FProcMeshTangent> Tangents;

    AHazePlayerCharacter Zoe;

    UPROPERTY(EditAnywhere)
    bool bDebugDrawTriangles = false;

    UPROPERTY(EditAnywhere, Meta = (EditCondition = "bDebugDrawTriangles"))
    int DrawTriangleIndex = -1;

    UPROPERTY(EditAnywhere)
    bool bDebugDrawSamplePoints = false;

    UPROPERTY(EditAnywhere)
    bool bDebugDrawVertices = false;

    UPROPERTY(EditAnywhere)
    bool bDebugDrawNormals = false;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if(bDebugDrawTriangles)
            DrawTriangleIndex = Math::Clamp(DrawTriangleIndex, -1, Triangles.Num() - 1);
        else
            DrawTriangleIndex = -1;
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateVertices();
		UpdateMeshSection_LinearColor(
			0,
			Vertices,
			Normals,
			UV0,
			UV1,
			UV0,
			UV0,
			VertexColors,
			Tangents
		);
	}

	void UpdateVertices()
	{
        float DistanceAlongSpline = GetPlayerDistanceAlongSpline();
        Debug::DrawDebugString(Zoe.ActorLocation, f"{DistanceAlongSpline}", FLinearColor::Green);
        float IntervalX = SizeX / ResolutionX;

        // Only traverse on one column, and then we just copy it over
        int VertexIndex = 0;
		for (int x = 0; x < Vertices.Num(); x += ResolutionY)
		{
            float DistFromMiddle = (x * IntervalX) - (SizeX);
            float VertexDistanceAlongSpline = DistanceAlongSpline + DistFromMiddle;

            FVector SplinePos = GetWorldPosLerped(Spawner.Alpha, VertexDistanceAlongSpline);
            FRotator SplineRot = GetWorldRotLerped(Spawner.Alpha, VertexDistanceAlongSpline);

            //SplinePos -= SplineRot.RotateVector(FVector::UpVector * 400);

            if(bDebugDrawSamplePoints)
            {
                Debug::DrawDebugString(SplinePos, f"{x}: {VertexDistanceAlongSpline}", FLinearColor::Red);
                Debug::DrawDebugPoint(SplinePos, 10.0, FLinearColor::Red);
            }

            FVector VertexPos = WorldTransform.InverseTransformPositionNoScale(SplinePos);

            float VertexY = 0.0;
            float IntervalY = SizeY / (ResolutionY - 1);
            for(int y = 0; y < ResolutionY; y++)
            {
			    Vertices[VertexIndex] = FVector(VertexPos.X, VertexY, VertexPos.Z);
                Normals[VertexIndex] = WorldTransform.InverseTransformVectorNoScale(SplineRot.UpVector);
                VertexY += IntervalY;

                if(bDebugDrawVertices || bDebugDrawNormals)
                {
                    FVector VertexWorldPos = WorldTransform.TransformPositionNoScale(Vertices[VertexIndex]);

                    if(bDebugDrawVertices)
                        Debug::DrawDebugPoint(VertexWorldPos, 30.0, FLinearColor::Blue);

                    if(bDebugDrawNormals)
                        Debug::DrawDebugDirectionArrow(VertexWorldPos, SplineRot.UpVector, 50.0, 5.0, FLinearColor::Red);
                }

                VertexIndex++;
            }
		}

        if(bDebugDrawTriangles)
        {
            DrawTriangleIndex = Math::Clamp(DrawTriangleIndex, -1, Triangles.Num() - 1);

            if(DrawTriangleIndex < 0)
            {
                for(int i = 0; i < Triangles.Num(); i++)
                {
                    DrawTriangle(i);
                }
            }
            else
            {
                DrawTriangle(DrawTriangleIndex);
            }
        }
	}

	UFUNCTION()
	void Preview()
	{
		Initialize();
	}

	void Initialize()
	{
        Zoe = Game::GetZoe();

		Triangles.Reset();
		ClearAllMeshSections();

		Vertices.Reserve(ResolutionX * ResolutionY);
        Normals.Reserve(Vertices.Num());
        Triangles.Reserve((Vertices.Num() - 2) * 3);

        CreateGrid();
		UpdateVertices();

        TArray<int> TriangleIndices;
        for(int i = 0; i < Triangles.Num(); i++)
        {
            TriangleIndices.Add(Triangles[i].Vertex0);
            TriangleIndices.Add(Triangles[i].Vertex1);
            TriangleIndices.Add(Triangles[i].Vertex2);
        }

		CreateMeshSection_LinearColor(
			0,
			Vertices,
			TriangleIndices,
			Normals,
			UV0,
			UV1,
			UV0,
			UV0,
			VertexColors,
			Tangents,
			true
		);
	}

    float GetPlayerDistanceAlongSpline() const
    {
        FVector PlayerLocation = Zoe.GetActorLocation();
        float UpDistanceAlongSpline = SplineCompUp.GetClosestSplineDistanceToWorldLocation(PlayerLocation);
        float DownDistanceAlongSpline = SplineCompDown.GetClosestSplineDistanceToWorldLocation(PlayerLocation);
        float DistanceAlongSpline = Math::Lerp(UpDistanceAlongSpline, DownDistanceAlongSpline, Spawner.Alpha);
        return DistanceAlongSpline;
    }

    void CreateGrid()
    {
        float IntervalX = SizeX / ResolutionX;
        float IntervalY = SizeY / ResolutionY;
        for(int x = 0; x < ResolutionX; x++)
        {
            float PosX = x * IntervalX;
            for(int y = 0; y < ResolutionY; y++)
            {
                float PosY = y * IntervalY;
                Vertices.Add(FVector(PosX, PosY, 0.0));
                Normals.Add(FVector::UpVector);
            }
        }

        for(int j = 0; j < ResolutionX - 1; j++)
        {
            int idx = j * ResolutionY;
            for(int i = 0; i < ResolutionY - 1; i++)
            {
                FSplineCorridorColliderTriangle Triangle1;
                Triangle1.Vertex0 = idx;
                Triangle1.Vertex1 = idx + 1;
                Triangle1.Vertex2 = idx + ResolutionY;

                Triangles.Add(Triangle1);

                FSplineCorridorColliderTriangle Triangle2;
                Triangle2.Vertex0 = idx + 1;
                Triangle2.Vertex1 = idx + ResolutionY + 1;
                Triangle2.Vertex2 = idx + ResolutionY;

                Triangles.Add(Triangle2);

                idx++;
            }
        }
    }

    private FVector GetWorldPosLerped(float Alpha, float Distance)
    {
        return Math::Lerp(CalculateWorldPos(SplineCompUp, Distance), CalculateWorldPos(SplineCompDown, Distance), Alpha);
    }

    private FVector CalculateWorldPos(UHazeSplineComponent SplineComp, float Distance)
    {
        return SplineComp.GetWorldLocationAtSplineDistance(Distance);
    }

    private FRotator GetWorldRotLerped(float Alpha, float Distance)
    {
        return Math::LerpShortestPath(CalculateWorldRot(SplineCompUp, Distance).Rotator(), CalculateWorldRot(SplineCompDown, Distance).Rotator(), Alpha);
    }

    private FQuat CalculateWorldRot(UHazeSplineComponent SplineComp, float Distance)
    {
        return SplineComp.GetWorldRotationAtSplineDistance(Distance);
    }

    ASplineCorridorBendActorSplineSpawner GetSpawner() const property
    {
        return Cast<ASplineCorridorBendActorSplineSpawner>(Owner);
    }

    UHazeSplineComponent GetSplineCompUp() const property
    {
        return Spawner.SplineCompUp;
    }

    UHazeSplineComponent GetSplineCompDown() const property
    {
        return Spawner.SplineCompDown;
    }

    void DrawTriangle(int TriangleIndex)
    {
        auto Triangle = Triangles[TriangleIndex];
        FVector Vector0 = WorldTransform.TransformPositionNoScale(Vertices[Triangle.Vertex0]);
        FVector Vector1 = WorldTransform.TransformPositionNoScale(Vertices[Triangle.Vertex1]);
        FVector Vector2 = WorldTransform.TransformPositionNoScale(Vertices[Triangle.Vertex2]);

        Debug::DrawDebugString(Vector0, "" + Triangle.Vertex0);
        Debug::DrawDebugString(Vector1, "" + Triangle.Vertex1);
        Debug::DrawDebugString(Vector2, "" + Triangle.Vertex2);
        Debug::DrawDebugString((Vector0 + Vector1 + Vector2) / 3, "Triangle" + TriangleIndex);

        Debug::DrawDebugLine(Vector0, Vector1);
        Debug::DrawDebugLine(Vector1, Vector2);
        Debug::DrawDebugLine(Vector2, Vector0);
    }

    int GetClosestSplinePointOnPlane(UHazeSplineComponent InSplineComp, FTransform InWorldTransform, FVector InSampleLoc)
    {
        FVector2D SampleLoc = FVector2D(InSampleLoc.X, InSampleLoc.Y);

        int ClosestIndex = -1;
        float ClosestDistanceSqr = 0.0;

        for(int i = 0; i < InSplineComp.SplinePoints.Num(); i++)
        {
            FVector SplinePointLoc = InWorldTransform.TransformPosition(InSplineComp.SplinePoints[i].RelativeLocation);
            FVector2D SplinePointOnPlane = FVector2D(SplinePointLoc.X, SplinePointLoc.Y);
            float DistanceSqr = SampleLoc.DistSquared(SplinePointOnPlane);
            if(DistanceSqr < ClosestDistanceSqr || ClosestIndex < 0)
            {
                ClosestIndex = i;
                ClosestDistanceSqr = DistanceSqr;
            }
        }

        return ClosestIndex;
    }
}