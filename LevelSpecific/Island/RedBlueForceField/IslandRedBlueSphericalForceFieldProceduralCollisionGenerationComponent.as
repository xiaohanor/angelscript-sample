class UIslandRedBlueSphericalForceFieldProceduralCollisionGenerationComponent : UActorComponent
{
	AIslandRedBlueForceField ForceField;
	UIslandRedBlueForceFieldProceduralCollisionComponent ProceduralCollisionComp;
	FIslandRedBlueForceFieldProceduralCollisionData FullIcosphereCollisionData;

	FIslandRedBlueForceFieldProceduralCollisionData CurrentCollisionData;

	UPROPERTY(EditAnywhere)
	bool bDebugShowMesh = false;

	UPROPERTY(EditAnywhere)
	bool bDebugDrawTriangles = false;

	/* If true the mesh will be inside out so the triangles face into the sphere, if false they will face outward and keep physics objects outside instead of inside. */
	UPROPERTY(EditAnywhere)
	bool bKeepPhysicsObjectsInside = true;

	UPROPERTY(EditAnywhere)
	int IcosahedronSubdivisionIterations = 3;

	uint64 LastForceFieldChangeId = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceField = Cast<AIslandRedBlueForceField>(Owner);
		devCheck(ForceField != nullptr, "Tried to add a UIslandRedBlueSphericalForceFieldProceduralCollisionGenerationComponent to an actor that is not a force field");
		devCheck(ForceField.bIsSphereForceField, "Tried to add a UIslandRedBlueSphericalForceFieldProceduralCollisionGenerationComponent to a force field that isn't sphere");

		ProceduralCollisionComp = UIslandRedBlueForceFieldProceduralCollisionComponent::Create(ForceField);
		ProceduralCollisionComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
		ProceduralCollisionComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Block);

		if(!bDebugShowMesh)
			ProceduralCollisionComp.AddComponentVisualsBlocker(this);

		ProceduralCollisionComp.WorldLocation = ForceField.CollisionMesh.WorldLocation;
		FBox Box = ForceField.CollisionMesh.GetBoundingBoxRelativeToOwner();
		ProceduralCollisionComp.RelativeScale3D = FVector(Box.Extent.X, Box.Extent.X, Box.Extent.X);

		GenerateIcosahedron(FullIcosphereCollisionData);
		SubdivideIcosahedronIntoIcosphere(FullIcosphereCollisionData, IcosahedronSubdivisionIterations);
		
		// Triangles are inside-out, facing into the sphere by default, so if they shouldn't do that we want to reverse the triangle array.
		if(!bKeepPhysicsObjectsInside)
			ReverseTriangles(FullIcosphereCollisionData);

		CurrentCollisionData = FullIcosphereCollisionData;

		GenerateMesh(CurrentCollisionData);
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
		GetIcosphereWithForceFieldHoles(CurrentCollisionData);

		// If the amount of triangles haven't changed we don't want to update the procedural mesh
		if(PreviousTrianglesNum == CurrentCollisionData.Triangles.Num())
			return;

		GenerateMesh(CurrentCollisionData);
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

	void GetIcosphereWithForceFieldHoles(FIslandRedBlueForceFieldProceduralCollisionData& CollisionData)
	{
		// Early out if there are no holes to save on performance.
		if(ForceField.HoleData.Num() == 0)
		{
			// Only copy full icosphere collision data to current if the triangle count differs between the two.
			if(CollisionData.Triangles.Num() == FullIcosphereCollisionData.Triangles.Num())
				return;

			CollisionData = FullIcosphereCollisionData;
			return;
		}
		
		CollisionData.Triangles.Reset(FullIcosphereCollisionData.Triangles.Num());
		for(int i = 0; i < Math::IntegerDivisionTrunc(FullIcosphereCollisionData.Triangles.Num(), 3); i++)
		{
			int TriangleStartIndex = i * 3;
			FVector WorldCenter = GetWorldCenterOfTriangle(FullIcosphereCollisionData, i);

			if(!ForceField.IsPointInsideHoles(WorldCenter))
			{
				CollisionData.Triangles.Add(FullIcosphereCollisionData.Triangles[TriangleStartIndex]);
				CollisionData.Triangles.Add(FullIcosphereCollisionData.Triangles[TriangleStartIndex + 1]);
				CollisionData.Triangles.Add(FullIcosphereCollisionData.Triangles[TriangleStartIndex + 2]);
			}
		}
	}

	void SubdivideIcosahedronIntoIcosphere(FIslandRedBlueForceFieldProceduralCollisionData& CollisionData, int SubdivisionIterations)
	{
		// For each triangle we make three new points in the middle of each edge, normalize those,
		// and create 4 new triangles from the 3 old and the 3 new points.
		// Like this:
		//			 B
		// 			 ╱╲
		//	   		╱  ╲
		// 	  	   ╱ 4  ╲
		//	   AB ╱______╲ BC
		//		 ╱ ╲ 1	╱ ╲
		//		╱ 2	╲  ╱ 3 ╲
		//	 A ╱_____╲╱_____╲ C
		//			 CA

		TArray<int> NewTriangles;
		NewTriangles.Reserve(Math::FloorToInt(CollisionData.Triangles.Num() * Math::Pow(4, SubdivisionIterations)));
		for(int i = 0; i < SubdivisionIterations; i++)
		{
			NewTriangles.Reset();

			for(int j = 0; j < CollisionData.Triangles.Num() - 2; j += 3)
			{
				int Ai = CollisionData.Triangles[j];
				int Bi = CollisionData.Triangles[j + 1];
				int Ci = CollisionData.Triangles[j + 2];

				FVector A = CollisionData.Vertices[Ai];
				FVector B = CollisionData.Vertices[Bi];
				FVector C = CollisionData.Vertices[Ci];

				int ABi = CollisionData.Vertices.Num();
				int BCi = CollisionData.Vertices.Num() + 1;
				int CAi = CollisionData.Vertices.Num() + 2;

				// These are normalized in order to place the new vertices on the sphere surface.
				// Normally we do (A + B) * 0.5 but since we normalize we can skip the * 0.5
				FVector AB = (A + B).GetSafeNormal();
				FVector BC = (B + C).GetSafeNormal();
				FVector CA = (C + A).GetSafeNormal();

				CollisionData.Vertices.Add(AB);
				CollisionData.Vertices.Add(BC);
				CollisionData.Vertices.Add(CA);

				AddTriangle(NewTriangles, CAi, ABi, BCi);
				AddTriangle(NewTriangles, Ai, ABi, CAi);
				AddTriangle(NewTriangles, CAi, BCi, Ci);
				AddTriangle(NewTriangles, ABi, Bi, BCi);
			}

			CollisionData.Triangles = NewTriangles;
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

	void GenerateIcosahedron(FIslandRedBlueForceFieldProceduralCollisionData& OutCollisionData)
	{
		// Source: https://www.classes.cs.uchicago.edu/archive/2003/fall/23700/docs/handout-04.pdf

		const float T = (1.0 + Math::Sqrt(5.0)) / 2.0;
		// Multiplier will normalize all vertices to be a distance of 1 from the center
		const float Multiplier = 1.0 / Math::Sqrt(1.0 + Math::Square(T));

		OutCollisionData.Vertices.Add(FVector(T, 1.0, 0.0) * Multiplier); // Vertex 0
		OutCollisionData.Vertices.Add(FVector(-T, 1.0, 0.0) * Multiplier); // Vertex 1
		OutCollisionData.Vertices.Add(FVector(T, -1.0, 0.0) * Multiplier); // Vertex 2
		OutCollisionData.Vertices.Add(FVector(-T, -1.0, 0.0) * Multiplier); // Vertex 3
		OutCollisionData.Vertices.Add(FVector(1.0, 0.0, T) * Multiplier); // Vertex 4
		OutCollisionData.Vertices.Add(FVector(1.0, 0.0, -T) * Multiplier); // Vertex 5
		OutCollisionData.Vertices.Add(FVector(-1.0, 0.0, T) * Multiplier); // Vertex 6
		OutCollisionData.Vertices.Add(FVector(-1.0, 0.0, -T) * Multiplier); // Vertex 7
		OutCollisionData.Vertices.Add(FVector(0.0, T, 1.0) * Multiplier); // Vertex 8
		OutCollisionData.Vertices.Add(FVector(0.0, -T, 1.0) * Multiplier); // Vertex 9
		OutCollisionData.Vertices.Add(FVector(0.0, T, -1.0) * Multiplier); // Vertex 10
		OutCollisionData.Vertices.Add(FVector(0.0, -T, -1.0) * Multiplier); // Vertex 11

		// Normals should point out from the center (so since all vertices are already a size of 1, the normals can just straight up be the vertices).
		OutCollisionData.Normals = OutCollisionData.Vertices;

		AddTriangle(OutCollisionData.Triangles, 0, 8, 4); // Triangle 0
		AddTriangle(OutCollisionData.Triangles, 0, 5, 10); // Triangle 1
		AddTriangle(OutCollisionData.Triangles, 2, 4, 9); // Triangle 2
		AddTriangle(OutCollisionData.Triangles, 2, 11, 5); // Triangle 3
		AddTriangle(OutCollisionData.Triangles, 1, 6, 8); // Triangle 4
		AddTriangle(OutCollisionData.Triangles, 1, 10, 7); // Triangle 5
		AddTriangle(OutCollisionData.Triangles, 3, 9 ,6); // Triangle 6
		AddTriangle(OutCollisionData.Triangles, 3, 7, 11); // Triangle 7
		AddTriangle(OutCollisionData.Triangles, 0, 10, 8); // Triangle 8
		AddTriangle(OutCollisionData.Triangles, 1, 8, 10); // Triangle 9
		AddTriangle(OutCollisionData.Triangles, 2, 9, 11); // Triangle 10
		AddTriangle(OutCollisionData.Triangles, 11, 9, 3); // Triangle 11 (these vertices are reversed from the original since this triangle had it's face pointed outwards for some reason)
		AddTriangle(OutCollisionData.Triangles, 4, 2, 0); // Triangle 12
		AddTriangle(OutCollisionData.Triangles, 5, 0, 2); // Triangle 13
		AddTriangle(OutCollisionData.Triangles, 6, 1, 3); // Triangle 14
		AddTriangle(OutCollisionData.Triangles, 7, 3, 1); // Triangle 15
		AddTriangle(OutCollisionData.Triangles, 8, 6, 4); // Triangle 16
		AddTriangle(OutCollisionData.Triangles, 9, 4, 6); // Triangle 17
		AddTriangle(OutCollisionData.Triangles, 10, 5, 7); // Triangle 18
		AddTriangle(OutCollisionData.Triangles, 11, 7, 5); // Triangle 19
	}

	void AddTriangle(TArray<int>& Triangles, int A, int B, int C)
	{
		Triangles.Add(A);
		Triangles.Add(B);
		Triangles.Add(C);
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

	void DebugVertexNumber(const FIslandRedBlueForceFieldProceduralCollisionData& CollisionData, bool bDrawVertexNumber, bool bDrawVertexPoint)
	{
		for(int i = 0; i < CollisionData.Vertices.Num(); i++)
		{
			FVector Vertex = CollisionData.Vertices[i];
			FVector WorldVertex = ProceduralCollisionComp.WorldTransform.TransformPosition(Vertex);

			if(bDrawVertexPoint)
				Debug::DrawDebugSphere(WorldVertex, 5.0, 12, FLinearColor::Red, 3);

			if(bDrawVertexNumber)
				Debug::DrawDebugString(WorldVertex, f"{i}", FLinearColor::Red, 0.0, 1.5);
		}
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