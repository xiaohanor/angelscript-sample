class UIslandRedBluePlaneForceFieldProceduralCollisionGenerationComponent : UActorComponent
{
	FIslandRedBlueForceFieldProceduralCollisionData FullPlaneCollisionData;
	FIslandRedBlueForceFieldProceduralCollisionData CurrentCollisionData;

	UPROPERTY(EditAnywhere)
	float QuadSizeUnits = 25.0;

	UPROPERTY(EditAnywhere)
	bool bDebugShowMesh = false;

	UPROPERTY(EditAnywhere)
	bool bDebugDrawTriangles = false;

	UPROPERTY(EditAnywhere)
	bool bReverseTriangles = false;

	const float ZOffset = 1.0;

	AIslandRedBlueForceField ForceField;
	UIslandRedBlueForceFieldProceduralCollisionComponent ProceduralCollisionComp;
	uint64 LastForceFieldChangeId = 0;
	UIslandRedBlueForceFieldCollisionContainerComponent CollisionContainerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceField = Cast<AIslandRedBlueForceField>(Owner);
		ProceduralCollisionComp = UIslandRedBlueForceFieldProceduralCollisionComponent::Create(ForceField);
		CollisionContainerComp = UIslandRedBlueForceFieldCollisionContainerComponent::GetOrCreate(Game::Mio);
		ProceduralCollisionComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
		ProceduralCollisionComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Block);
		ProceduralCollisionComp.WorldLocation = ForceField.CollisionMesh.WorldLocation + FVector::UpVector * ZOffset;

		if(!bDebugShowMesh)
			ProceduralCollisionComp.AddComponentVisualsBlocker(this);

		GeneratePlane(FullPlaneCollisionData);

		if(bReverseTriangles)
			ReverseTriangles(FullPlaneCollisionData);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bDebugDrawTriangles)
			DebugTriangles(CurrentCollisionData, false, true);

		// Early out if the force field hasn't changed
		if(ForceField.ForceFieldChangeId == LastForceFieldChangeId)
			return;

		LastForceFieldChangeId = ForceField.ForceFieldChangeId;

		int PreviousTrianglesNum = CurrentCollisionData.Triangles.Num();
		GetPlaneWithForceFieldHoles(CurrentCollisionData);

		// If the amount of triangles haven't changed we don't want to update the procedural mesh
		if(PreviousTrianglesNum == CurrentCollisionData.Triangles.Num())
			return;

		GenerateMesh(CurrentCollisionData);
		WakeUpRigidbodies();
	}

	void WakeUpRigidbodies()
	{
		for(UPrimitiveComponent Primitive :  CollisionContainerComp.PrimitivePhysicsComponents)
		{
			FBox Bounds = ForceField.CollisionMesh.GetBoundingBoxRelativeToOwner();
			FVector LocalLocation = ForceField.ActorTransform.InverseTransformPosition(Primitive.WorldLocation);

			FVector ClosestPoint = Bounds.GetClosestPointTo(LocalLocation);

			if(ClosestPoint.DistSquared(LocalLocation) > Math::Square(100.0))
				continue;

			Primitive.WakeRigidBody();
		}
	}

	void ReverseTriangles(FIslandRedBlueForceFieldProceduralCollisionData& CollisionData)
	{
		TArray<int> NewTriangles;
		NewTriangles.Reserve(CollisionData.Triangles.Num());
		for(int i = CollisionData.Triangles.Num() - 1; i >= 0; i--)
		{
			NewTriangles.Add(CollisionData.Triangles[i]);
		}

		CollisionData.Triangles = NewTriangles;
	}

	void GenerateMesh(FIslandRedBlueForceFieldProceduralCollisionData&in CollisionData)
	{
		ProceduralCollisionComp.CreateMeshSection_LinearColor(
			0,
			CollisionData.Vertices,
			CollisionData.Triangles,
			CollisionData.Normals,
			CollisionData.UV,
			CollisionData.UV,
			CollisionData.UV,
			CollisionData.UV,
			CollisionData.VertexColors,
			CollisionData.Tangents,
			true
		);
	}

	private void GeneratePlane(FIslandRedBlueForceFieldProceduralCollisionData& PlaneData)
	{
		FBox Box = ForceField.CollisionMesh.GetBoundingBoxRelativeToOwner();
		int AmountOfQuadsY = Math::RoundToInt((Box.Extent.Y * 2.0) / QuadSizeUnits);
		int AmountOfQuadsZ = Math::RoundToInt((Box.Extent.Z * 2.0) / QuadSizeUnits);

		FVector Origin = FVector(0.0, -Box.Extent.Y + (QuadSizeUnits * 0.5), -Box.Extent.Z + (QuadSizeUnits * 0.5));
		// const int AmountToGenerate = 2;
		// int CurrentAmount = 0;
		for(int Z = 0; Z < AmountOfQuadsZ; Z++)
		{
			for(int Y = 0; Y < AmountOfQuadsY; Y++)
			{
				FVector QuadRelativeLocation = Origin + FVector(0.0, QuadSizeUnits * Y, QuadSizeUnits * Z);
				GenerateQuad(PlaneData, QuadRelativeLocation);
				// CurrentAmount++;
				// if(CurrentAmount == AmountToGenerate)
				// 	return;
			}
		}
	}

	private void GenerateQuad(FIslandRedBlueForceFieldProceduralCollisionData& PlaneData, FVector QuadRelativeLocation)
	{
		int StartIndex = PlaneData.Vertices.Num();

		float QuadExtents = QuadSizeUnits * 0.5;
		PlaneData.Vertices.Add(QuadRelativeLocation + FVector::DownVector * QuadExtents + FVector::LeftVector * QuadExtents); // Back left vertex
		PlaneData.Vertices.Add(QuadRelativeLocation + FVector::DownVector * QuadExtents + FVector::RightVector * QuadExtents); // Back right vertex
		PlaneData.Vertices.Add(QuadRelativeLocation + FVector::UpVector * QuadExtents + FVector::LeftVector * QuadExtents); // Front left vertex
		PlaneData.Vertices.Add(QuadRelativeLocation + FVector::UpVector * QuadExtents + FVector::RightVector * QuadExtents); // Front right vertex

		// Add one forward normal for each vertex
		for(int i = 0; i < 4; i++)
			PlaneData.Normals.Add(FVector::ForwardVector);

		PlaneData.Triangles.Add(StartIndex + 0);
		PlaneData.Triangles.Add(StartIndex + 1);
		PlaneData.Triangles.Add(StartIndex + 3);
		PlaneData.Triangles.Add(StartIndex + 3);
		PlaneData.Triangles.Add(StartIndex + 2);
		PlaneData.Triangles.Add(StartIndex + 0);
	}

	private void GetPlaneWithForceFieldHoles(FIslandRedBlueForceFieldProceduralCollisionData& CollisionData)
	{
		// Early out if there are no holes to save on performance.
		if(ForceField.HoleData.Num() == 0)
		{
			// Only copy full plane collision data to current if the triangle count differs between the two.
			if(CollisionData.Triangles.Num() == FullPlaneCollisionData.Triangles.Num())
				return;

			CollisionData = FullPlaneCollisionData;
			return;
		}
		
		CollisionData.Triangles.Reset(FullPlaneCollisionData.Triangles.Num());
		for(int i = 0; i < Math::IntegerDivisionTrunc(FullPlaneCollisionData.Triangles.Num(), 3); i++)
		{
			int TriangleStartIndex = i * 3;
			FVector WorldCenter = GetWorldCenterOfTriangle(FullPlaneCollisionData, i);

			if(!ForceField.IsPointInsideHoles(WorldCenter))
			{
				CollisionData.Triangles.Add(FullPlaneCollisionData.Triangles[TriangleStartIndex]);
				CollisionData.Triangles.Add(FullPlaneCollisionData.Triangles[TriangleStartIndex + 1]);
				CollisionData.Triangles.Add(FullPlaneCollisionData.Triangles[TriangleStartIndex + 2]);
			}
		}
	}

	void DebugTriangles(const FIslandRedBlueForceFieldProceduralCollisionData& CollisionData, bool bDrawTriangleNumbers, bool bDrawTriangleEdges)
	{
		int TriangleNumber = 0;
		for(int i = 0; i < CollisionData.Triangles.Num() - 2; i += 3)
		{
			FVector A = CollisionData.Vertices[CollisionData.Triangles[i]];
			FVector B = CollisionData.Vertices[CollisionData.Triangles[i + 1]];
			FVector C = CollisionData.Vertices[CollisionData.Triangles[i + 2]];
			
			if(bDrawTriangleNumbers)
			{
				FVector WorldCenterOfTriangle = GetWorldCenterOfTriangle(A, B, C);
				Debug::DrawDebugString(WorldCenterOfTriangle, f"{TriangleNumber}", FLinearColor::Red, 0.0, 1.0);
			}

			if(bDrawTriangleEdges)
			{
				FVector WorldA = ProceduralCollisionComp.WorldTransform.TransformPosition(A);
				FVector WorldB = ProceduralCollisionComp.WorldTransform.TransformPosition(B);
				FVector WorldC = ProceduralCollisionComp.WorldTransform.TransformPosition(C);

				Debug::DrawDebugLine(WorldA, WorldB, FLinearColor::Red, 2.0, 0.0);
				Debug::DrawDebugLine(WorldB, WorldC, FLinearColor::Red, 2.0, 0.0);
				Debug::DrawDebugLine(WorldC, WorldA, FLinearColor::Red, 2.0, 0.0);
			}

			++TriangleNumber;
		}
	}

	void AddTriangle(TArray<int>& Triangles, int A, int B, int C)
	{
		Triangles.Add(A);
		Triangles.Add(B);
		Triangles.Add(C);
	}

	FVector GetWorldCenterOfTriangle(const FIslandRedBlueForceFieldProceduralCollisionData& CollisionData, int TriangleIndex)
	{
		return ProceduralCollisionComp.WorldTransform.TransformPosition(GetLocalCenterOfTriangle(CollisionData, TriangleIndex));
	}

	FVector GetWorldCenterOfTriangle(FVector VertexA, FVector VertexB, FVector VertexC)
	{
		return ProceduralCollisionComp.WorldTransform.TransformPosition(GetLocalCenterOfTriangle(VertexA, VertexB, VertexC));
	}

	FVector GetLocalCenterOfTriangle(const FIslandRedBlueForceFieldProceduralCollisionData& CollisionData, int TriangleIndex)
	{
		int StartTriangleIndex = TriangleIndex * 3;
		int Ai = CollisionData.Triangles[StartTriangleIndex];
		int Bi = CollisionData.Triangles[StartTriangleIndex + 1];
		int Ci = CollisionData.Triangles[StartTriangleIndex + 2];

		FVector A = CollisionData.Vertices[Ai];
		FVector B = CollisionData.Vertices[Bi];
		FVector C = CollisionData.Vertices[Ci];

		return GetLocalCenterOfTriangle(A, B, C);
	}

	FVector GetLocalCenterOfTriangle(FVector VertexA, FVector VertexB, FVector VertexC)
	{
		return FVector(
			(VertexA.X + VertexB.X + VertexC.X) / 3.0,
			(VertexA.Y + VertexB.Y + VertexC.Y) / 3.0,
			(VertexA.Z + VertexB.Z + VertexC.Z) / 3.0);
	}
}