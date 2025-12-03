class USketchbookBowTrajectoryMeshComponent : UProceduralMeshComponent
{
	default CollisionEnabled = ECollisionEnabled::NoCollision;

	//MESH SETTINGS
	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;
	
	UMaterialInstanceDynamic DynamicMat;

	UPROPERTY(EditAnywhere)
	const int Resolution = 6;

	UPROPERTY(EditAnywhere)
	const float Thickness = 2;

	//MESH DATA
	TArray<FVector> Vertices;
	TArray<int> Triangles;

	TArray<FVector> Normals;
	TArray<FVector2D> UV0;
	TArray<FVector2D> UV1;
	TArray<FLinearColor> VertexColors;
	TArray<FProcMeshTangent> Tangents;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResetMesh();

		DynamicMat = Material::CreateDynamicMaterialInstance(this, Material);
		SetMaterial(0, DynamicMat);

		SetAbsolute(true, true, true);
	}

	void ResetMesh()
	{
		Vertices.Reset();
		Triangles.Reset();
		Normals.Reset();
		Tangents.Reset();
		UV0.Reset();

		ClearAllMeshSections();
	}

	void SetAlpha(const float Alpha)
	{
		DynamicMat.SetScalarParameterValue(n"Alpha", Alpha);
	}

	void RecreateMesh(FHazeRuntimeSpline Spline)
	{
		ResetMesh();

		if(Spline.Length < 1)
			return;

		const float TrajectoryLenght = Math::Min(Spline.Length, 1000);
		
		const float MeshRingInterval = 10;
		float DistanceAlongSpline = MeshRingInterval;
		const float AngleStep = TWO_PI / Resolution;

		FVector TargetLocation;
		FVector TargetDirection;
		Spline.GetLocationAndDirectionAtDistance(KINDA_SMALL_NUMBER, TargetLocation, TargetDirection);

		FVector LastForward = (Spline.GetLocationAtDistance(MeshRingInterval) - TargetLocation).GetSafeNormal();
		FVector LastLocation = TargetLocation + (LastForward * -MeshRingInterval);
		float LastRingDistance = KINDA_SMALL_NUMBER;


		while(DistanceAlongSpline < TrajectoryLenght)
		{
			const float U = DistanceAlongSpline / TrajectoryLenght;

			Spline.GetLocationAndDirectionAtDistance(DistanceAlongSpline, TargetLocation, TargetDirection);
			AddRingAtDistance(TargetLocation, TargetDirection, U, AngleStep);
			LastLocation = TargetLocation;
			LastForward = TargetDirection;
			LastRingDistance = DistanceAlongSpline;

			DistanceAlongSpline += MeshRingInterval;
		}

		const int RingCount = Math::IntegerDivisionTrunc(Vertices.Num(), Resolution+1);

		if(RingCount < 2)
			return;

		for(int RingIndex = 0; RingIndex < RingCount - 1; RingIndex++)
		{
			for(int32 RingVertexIndex = 0; RingVertexIndex < Resolution; RingVertexIndex++)
			{
				int32 TL = GetVertIndex(RingIndex, RingVertexIndex);
				int32 BL = GetVertIndex(RingIndex, RingVertexIndex + 1);
				int32 TR = GetVertIndex(RingIndex + 1, RingVertexIndex);
				int32 BR = GetVertIndex(RingIndex + 1, RingVertexIndex + 1);

				Triangles.Add(TL);
				Triangles.Add(TR);
				Triangles.Add(BL);

				Triangles.Add(TR);
				Triangles.Add(BR);
				Triangles.Add(BL);
			}
		}

		CreateMeshSection_LinearColor(
			0,
			Vertices,
			Triangles,
			Normals,
			UV0,
			UV1,
			UV0,
			UV0,
			VertexColors,
			Tangents,
			false
		);
	}

	private void AddRingAtDistance(FVector Location, FVector Direction, float AlongFraction, float AngleStep)
	{
		// Create a ring of vertices at the location
		for (int i = 0; i <= Resolution; i++)
		{
			FVector Right = FVector::ForwardVector.CrossProduct(Direction);

			Right = Right.GetSafeNormal();

			FVector Normal = FQuat(Direction, AngleStep * i) * Right;

			if(!Math::IsNearlyEqual(Math::Abs(Normal.DotProduct(Direction)), 0))
			{
				PrintWarning("Somting wong wid da normal, it bad //Filip");
				Normal = Normal.VectorPlaneProject(Direction).GetSafeNormal();
			}
			
			FVector VertexLocation = Location + Normal * Thickness;
			Vertices.Add(VertexLocation);
			Normals.Add(Normal);

			const float RingFraction = (i  / float(Resolution));
			FVector2D UV = FVector2D(AlongFraction, RingFraction);
			UV0.Add(UV);
		}
	}
	
	private int32 GetVertIndex(int32 AlongIdx, int32 AroundIdx) const
	{
		return (AlongIdx * (Resolution+1)) + AroundIdx;
	}

};