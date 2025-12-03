struct FYarnSplinePoint
{
	FVector LastLocation;
	int SplinePointIndex = -1;
	float SpawnTime;
	bool bIsSleeping = false;
	float FallSpeed = 200;
	const float FallSpeedIncreasePerSecond = 100;

	FYarnSplinePoint (int Index, FVector SpawnLocation)
	{
		SplinePointIndex = Index;
		LastLocation = SpawnLocation;
		SpawnTime = Time::GameTimeSeconds;
	}
}

class UMoonMarketYarnTrailComponent : UProceduralMeshComponent
{
	default CollisionEnabled = ECollisionEnabled::NoCollision;

	//YARN SETTINGS
	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;
	const int Resolution = 9;
	const float Thickness = 5;
	const float MaxYarnLength = 10000;

	//MESH DATA
	TArray<FVector> Vertices;
	TArray<int> Triangles;

	TArray<FVector> Normals;
	TArray<FVector2D> UV0;
	TArray<FVector2D> UV1;
	TArray<FLinearColor> VertexColors;
	TArray<FProcMeshTangent> Tangents;

	//SPLINE SETTINGS
	const float PointSpacing = 10;

	//RUNTIME SPLINE DATA
	FHazeRuntimeSpline YarnSpline;
	TArray<FYarnSplinePoint> PointsData;
	FVector LastYarnSpawnPoint;

	bool bIsFinished = false;

	UPROPERTY()
	FRuntimeFloatCurve YarnBallScaleCurve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsFinished)
			SpawnNewSplinePoints();
		
		UpdateExistingSplinePoints(DeltaSeconds);
		RecreateYarnMesh();
	}

	void SpawnNewSplinePoints()
	{
		float PointSpacingMultiplier = 1 - (Math::Clamp(Owner.ActorVelocity.Size() / PointSpacing, 0, 1));

		if(Owner.ActorLocation.Distance(LastYarnSpawnPoint) > PointSpacing * PointSpacingMultiplier)
		{
			AddSplinePoint();
			float Percentage = YarnSpline.Length / MaxYarnLength;

			if(Percentage >= 0.99)
			{
				Owner.SetActorScale3D(FVector::ZeroVector);
				bIsFinished = true;
				Owner.AddActorTickBlock(this);
				Owner.AddActorCollisionBlock(this);
				DetachFromParent();
			}
			else
			{
				FVector NewScale = FVector::OneVector * YarnBallScaleCurve.GetFloatValue(Percentage);
				Owner.SetActorScale3D(NewScale);
			}
		}
	}

	void UpdateExistingSplinePoints(float DeltaSeconds)
	{
		FHazeTraceSettings TraceSettings = Trace::InitObjectType(EObjectTypeQuery::WorldStatic);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(Owner);

		for(auto& SplinePoint : PointsData)
		{
			if(SplinePoint.bIsSleeping)
				continue;

			//This spline point has likely fallen off an edge. Stop tracing
			if(Time::GetGameTimeSince(SplinePoint.SpawnTime) > 5)
			{
				SplinePoint.bIsSleeping = true;
				continue;
			}

			const FVector Location = YarnSpline.GetPoints()[SplinePoint.SplinePointIndex];
			const FVector End = Location + FVector::DownVector * Thickness;
			const FHitResult GroundHit = TraceSettings.QueryTraceSingle(SplinePoint.LastLocation, End);
			
			if(GroundHit.bBlockingHit && (GroundHit.Location.Z - Location.Z) <= Thickness * 1.5)
			{
				YarnSpline.SetPoint(GroundHit.Location + FVector::UpVector * Thickness, SplinePoint.SplinePointIndex);
				SplinePoint.bIsSleeping = true;
			}
			else
			{
				YarnSpline.SetPoint(Location - FVector::UpVector * SplinePoint.FallSpeed * DeltaSeconds, SplinePoint.SplinePointIndex);
			}

			SplinePoint.LastLocation = Location;
			SplinePoint.FallSpeed += DeltaSeconds * SplinePoint.FallSpeedIncreasePerSecond;
		}

		if(PointsData.Last().bIsSleeping)
			SetComponentTickEnabled(false);
	}

	void AddSplinePoint()
	{
		PointsData.Add(FYarnSplinePoint(YarnSpline.Points.Num(), Owner.ActorLocation));
		YarnSpline.AddPoint(LastYarnSpawnPoint);
		LastYarnSpawnPoint = Owner.ActorLocation;

		RecreateYarnMesh();
	}

	void Initialize()
	{
		ClearAllMeshSections();

		UV0.SetNumZeroed(Resolution + 1);

		SetMaterial(0, Material);		

		LastYarnSpawnPoint = Owner.ActorLocation;
		SetAbsolute(true, true, true);
		AddSplinePoint();
		SetComponentTickEnabled(true);
	}

	int32 GetVertIndex(int32 AlongIdx, int32 AroundIdx) const
	{
		return (AlongIdx * (Resolution+1)) + AroundIdx;
	}

	private void RecreateYarnMesh()
	{
		if(YarnSpline.Points.Num() < 2)
			return;

		if(YarnSpline.Length < 1)
			return;
		
		Vertices.Reset();
		Triangles.Reset();
		Normals.Reset();
		Tangents.Reset();
		UV0.Reset();

		float DistanceAlongSpline = KINDA_SMALL_NUMBER;
		const float MeshRingInterval = 10;
		const float MaxMeshRingInterval = 100;
		const float AngleStep = TWO_PI / Resolution;

		FVector TargetLocation;
		FVector TargetDirection;
		YarnSpline.GetLocationAndDirectionAtDistance(KINDA_SMALL_NUMBER, TargetLocation, TargetDirection);

		FVector LastForward = (YarnSpline.GetLocationAtDistance(10) - TargetLocation).GetSafeNormal();
		FVector LastLocation = TargetLocation + (LastForward * -10);
		float LastRingDistance = KINDA_SMALL_NUMBER;
		AddRingAtDistance(LastLocation, LastForward, LastRingDistance, AngleStep);

		while(DistanceAlongSpline < YarnSpline.Length)
		{
			TargetLocation = YarnSpline.GetLocationAtDistance(DistanceAlongSpline);
			TargetDirection = YarnSpline.GetDirectionAtDistance(DistanceAlongSpline);
			const float AngularDistance = TargetDirection.AngularDistance(LastForward);
			const bool bSharpTurn = AngularDistance > 0.4;
			const float SubstepsPerRadian = 1;
			const bool bTooFar = (DistanceAlongSpline - LastRingDistance) > MaxMeshRingInterval;

			//If the angle distance is too large
			if(bSharpTurn)
			{
				int SubStepCount = Math::CeilToInt(AngularDistance * SubstepsPerRadian);

				//Substep through the angle distance
				for(int SubStep = 1; SubStep < SubStepCount + 1; SubStep++)
				{
					float Percent = SubStep / float(SubStepCount + 1);
					float SubstepDistance = Math::Lerp(LastRingDistance, DistanceAlongSpline, Percent);

					//Debug::DrawDebugDirectionArrow(TargetLocation, FVector::UpVector, AngularDistance * 200, 2, FLinearColor::Green, 0.5);

					FVector SubstepLocation;
					FVector SubstepDirection;
					YarnSpline.GetLocationAndDirectionAtDistance(SubstepDistance, SubstepLocation, SubstepDirection);

					AddRingAtDistance(SubstepLocation, SubstepDirection, SubstepDistance, AngleStep);

					LastRingDistance = SubstepDistance;
					LastLocation = SubstepLocation;
					LastForward = SubstepDirection;
				}
			}
			else if(bTooFar)
			{
				AddRingAtDistance(TargetLocation, TargetDirection, DistanceAlongSpline, AngleStep);
				LastLocation = TargetLocation;
				LastForward = TargetDirection;
				LastRingDistance = DistanceAlongSpline;
			}

			DistanceAlongSpline += MeshRingInterval;
		}

		YarnSpline.GetLocationAndDirectionAtDistance(YarnSpline.Length - KINDA_SMALL_NUMBER, TargetLocation, TargetDirection);
		AddRingAtDistance(TargetLocation, TargetDirection, YarnSpline.Length, AngleStep);

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

	private void AddRingAtDistance(FVector Location, FVector Direction, float DistanceAlongSpline, float AngleStep)
	{
		// Create a ring of vertices at the location
		for (int i = 0; i <= Resolution; i++)
		{
			FVector Right = FVector::UpVector.CrossProduct(Direction);

			if(Direction.DotProduct(FVector::UpVector) > 0.99)
				Right = Direction.CrossProduct(FVector::ForwardVector);

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

			const float AlongFraction = DistanceAlongSpline / 50;
			//Debug::DrawDebugString(VertexLocation, f"{AlongFraction}", FLinearColor::White);
			const float RingFraction = (i  / float(Resolution));
			FVector2D UV = FVector2D(AlongFraction, RingFraction);
			UV0.Add(UV);
		}
	}
};