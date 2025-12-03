// Todo: shape presets

enum ECritterSurfaceShapePresets
{
	Square,
	Circle,
	Test,
}

struct FCritterSurfaceCritter
{
	UPROPERTY()
	UStaticMeshComponent MeshComp;

	UPROPERTY()
	float MoveTimer = 0.0;

	UPROPERTY()
	float MoveDuration = 0.0;

	UPROPERTY()
	FVector2D StartSurfacePosition;

	UPROPERTY()
	FVector StartRelativePosition;

	UPROPERTY()
	FRotator StartRotation;

	UPROPERTY()
	FVector2D DestSurfacePosition;

	UPROPERTY()
	FVector DestRelativePosition;

	UPROPERTY()
	FRotator DestRotation;

	UPROPERTY()
	bool bIsRunningAway = false;
}

struct FCritterSurfacePointArray
{
	UPROPERTY()
	TArray<FVector> Points;
}

struct FCritterSurfaceMeshSampleData
{
	FVector P0;
	FVector P1;
	FVector P2;
	FVector P3;
	FVector2D Fraction;
	bool Valid;
}

class ACritterSurface : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.0;
	
#if EDITOR
	UPROPERTY(DefaultComponent)
	UBoxComponent PreviewBox;
	default PreviewBox.CollisionProfileName = n"NoCollision";
#endif

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	float CritterSpeed = 0.1;

	UPROPERTY(EditAnywhere)
	int NumberOfCritters = 10;

	UPROPERTY(EditAnywhere, Category="Surface")
	ECritterSurfaceShapePresets ShapePreset;

	UPROPERTY(EditAnywhere, Category="Surface", meta = (ClampMin = 0.0, ClampMax = 1.0), Meta = (EditCondition="ShapePreset == ECritterSurfaceShapePresets::Square", EditConditionHides))
	float SquareRoundness = 0.2;

	UPROPERTY(EditAnywhere, Category="Surface", meta = (ClampMin = 0.0, ClampMax = 1.0), Meta = (EditCondition="ShapePreset == ECritterSurfaceShapePresets::Circle", EditConditionHides))
	float CircleAngle = 0.4;

	UPROPERTY(EditAnywhere, Category="Surface", meta = (ClampMin = 0.0, ClampMax = 1.0), Meta = (EditCondition="ShapePreset == ECritterSurfaceShapePresets::Circle", EditConditionHides))
	float CircleHole = 0.5;

	UPROPERTY(EditAnywhere, Category="Surface", meta = (ClampMin = 2.0, ClampMax = 32.0))
	int ResolutionX = 8;

	UPROPERTY(EditAnywhere, Category="Surface", meta = (ClampMin = 2.0, ClampMax = 32.0))
	int ResolutionY = 8;

	UPROPERTY(EditAnywhere, Category="Surface")
	float Width = 500;

	UPROPERTY(EditAnywhere, Category="Surface")
	float Height = 500;
	
	UPROPERTY(EditAnywhere, Category="Surface")
	float Perspective = 0.0;
	
	UPROPERTY(EditAnywhere, Category="Surface")
	float PushDistance = 0.25;
	
	UPROPERTY(EditAnywhere, Category="zzInternal")
	TArray<FCritterSurfaceCritter> Critters;

	UPROPERTY(EditAnywhere, Category="zzInternal")
	TArray<FVector> Points;

	UPROPERTY(EditAnywhere, Category="zzInternal")
	FTransform ProjectedTransform;

	FVector2D Pattern_Square(FVector2D Coordinate)
	{
		float t = Math::Clamp(SquareRoundness, 0.0, 1.0);
		float tweak = Math::Pow(t, 0.25);
		tweak = Math::GetMappedRangeValueClamped(FVector2D(1, 0),FVector2D(1.4, 10.0),tweak);
		float dist = tweak - Coordinate.Distance(FVector2D::ZeroVector);
		return Coordinate * dist * (1.0/tweak) * ((t*0.5) + 1);
	}

	FVector2D Pattern_Circle(FVector2D Coordinate)
	{
		float x = Coordinate.X + 0.5;
		float y = Coordinate.Y + 0.5;
		y = Math::GetMappedRangeValueClamped(FVector2D(0, 1), FVector2D(CircleHole, 1), y);
		
		float angle = x * 3.14152128 * 2.0 * CircleAngle;
		float X = Math::Sin(angle);
		float Y = Math::Cos(angle);

		return FVector2D(X, Y) * y * 0.5;
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void RecalculateAllCritterSurfaces()
	{
		TArray<ACritterSurface> AllSurfaces = Editor::GetAllEditorWorldActorsOfClass(ACritterSurface);

		for (auto OtherSurface : AllSurfaces)
		{
			OtherSurface.Construction_UpdateSurface();
			OtherSurface.Modify();
			OtherSurface.RerunConstructionScripts();
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		if (!Editor::IsCooking() && Level.IsVisible() && Editor::IsSelected(this))
			Construction_UpdateSurface();
#endif

		Construction_CreateCritters();
	}

	void Construction_UpdateSurface()
	{
		FVector ScaleDiff = GetActorScale3D() - FVector::OneVector;
		SetActorScale3D(FVector::OneVector);
		
		Width += ScaleDiff.X * 100.0;
		Height += ScaleDiff.Y * 100.0;

#if EDITOR
		PreviewBox.SetBoxExtent(FVector(Width, Height, 0));
#endif
		
		ProjectedTransform = GetActorTransform();
		Points.SetNum(ResolutionX * ResolutionY);

		if(ResolutionX < 2 || ResolutionY < 2)
			return;

		for (int x = 0; x < ResolutionX; x++)
		{
			for (int y = 0; y < ResolutionY; y++)
			{
				float X = (float(x) / float(ResolutionX-1)) - 0.5;
				float Y = (float(y) / float(ResolutionY-1)) - 0.5;
				
				FVector2D Pattern = FVector2D(X, Y);;

				if(ShapePreset == ECritterSurfaceShapePresets::Square)
				 	Pattern = Pattern_Square(FVector2D(X, Y));
				else if(ShapePreset == ECritterSurfaceShapePresets::Circle)
				 	Pattern = Pattern_Circle(FVector2D(X, Y));

				X = Pattern.X;
				Y = Pattern.Y;

				FVector ForwardVector = GetActorForwardVector() * X * Width * 2.0;
				FVector RightVector = GetActorRightVector() * Y * Height * 2.0;
				FVector OffsetVector = (ForwardVector + RightVector);

				float TraceLength = 10000;
				float persp = Perspective / 1000.0;

				FHazeTraceSettings Trace;
				Trace.TraceWithChannel(ECollisionChannel::ECC_Visibility);

				FVector StartLocation = (ActorLocation + OffsetVector);
				FVector EndLocation = (ActorLocation + OffsetVector + (OffsetVector) * (persp*TraceLength)) - GetActorUpVector()*TraceLength;

				FHitResult Result = Trace.QueryTraceSingle(StartLocation, EndLocation);
				if(Result.bBlockingHit)
				{
					Points[x + y * ResolutionX] = ProjectedTransform.InverseTransformPosition(Result.Location);
				}
				else
				{
					Points[x + y * ResolutionX] = ProjectedTransform.InverseTransformPosition(ActorLocation+OffsetVector);
				}
			}
		}
	}

	void Construction_CreateCritters()
	{
		// Make preview splines
		Critters.Reset();
		for (int i = 0; i < NumberOfCritters; i++)
		{
			auto NewMesh = CreateComponent(UStaticMeshComponent);
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";

			FCritterSurfaceCritter NewCritter = FCritterSurfaceCritter();
			
			NewCritter.MeshComp = NewMesh;
			FVector2D RandPosition = FVector2D(Math::RandRange(0.0f, 1.0f), Math::RandRange(0.0, 1.0));
			NewCritter.StartSurfacePosition = RandPosition;
			NewCritter.StartRelativePosition = RelativePosFromSurfacePos(RandPosition);
			NewCritter.StartRotation = FRotator::MakeFromZ(RelativeUpVectorFromSurfacePos(RandPosition));
			MakeNewCritterDestination(NewCritter);

			NewMesh.SetWorldLocation(ActorTransform.TransformPosition(NewCritter.StartRelativePosition));
			Critters.Add(NewCritter);
		}
	}

	void CritterReachDestination(FCritterSurfaceCritter& Critter)
	{
		Critter.StartRelativePosition = Critter.DestRelativePosition;
		Critter.StartSurfacePosition = Critter.DestSurfacePosition;
		Critter.StartRotation = Critter.DestRotation;
	}

	void MakeNewCritterDestination(FCritterSurfaceCritter& Critter)
	{
		FVector2D RandPosition = FVector2D(Math::RandRange(0.0, 1.0), Math::RandRange(0.0, 1.0));
		FVector2D SurfacePos = RandPosition;

		Critter.DestSurfacePosition = SurfacePos;
		Critter.DestRelativePosition = RelativePosFromSurfacePos(SurfacePos);

		FVector Direction = (Critter.DestRelativePosition - Critter.StartRelativePosition).GetSafeNormal();
		Critter.StartRotation = FRotator::MakeFromXZ(Direction, Critter.StartRotation.UpVector);
		Critter.DestRotation = FRotator::MakeFromXZ(Direction, RelativeUpVectorFromSurfacePos(SurfacePos));
		Critter.bIsRunningAway = false;

		Critter.MoveTimer = 0.0;

		float Distance = Critter.DestRelativePosition.Distance(Critter.StartRelativePosition);
		float Speed = Math::Max(CritterSpeed * float(Width + Height) * 0.5, 0.01);
		Critter.MoveDuration = Math::Max(Distance / Speed, 0.1);
	}

	void CritterRunawayFrom(FCritterSurfaceCritter& Critter, FVector DangerPositionRelative)
	{
		float MovePct = Critter.MoveTimer / Critter.MoveDuration;
		Critter.StartRelativePosition = Critter.MeshComp.RelativeLocation;
		Critter.StartRotation = Critter.MeshComp.RelativeRotation;
		Critter.StartSurfacePosition = Math::Lerp(Critter.StartSurfacePosition, Critter.DestSurfacePosition, MovePct);

		FVector RelativeDirection = (Critter.StartRelativePosition - DangerPositionRelative).GetSafeNormal();

		FVector2D SurfacePos = Critter.StartSurfacePosition;
		SurfacePos.X += RelativeDirection.X * CritterSpeed * 1.5;
		SurfacePos.Y += RelativeDirection.Y * CritterSpeed * 1.5;

		// If we're going too far outside the surface, try the opposite direction
		if (Math::Max(Math::Abs(SurfacePos.X) - 1.0, 0.0) + Math::Max(Math::Abs(SurfacePos.Y) - 1.0, 0.0) > CritterSpeed * 0.75)
		{
			SurfacePos = Critter.StartSurfacePosition;
			SurfacePos.X -= RelativeDirection.X * CritterSpeed * 1.5;
			SurfacePos.Y -= RelativeDirection.Y * CritterSpeed * 1.5;
		}

		SurfacePos.X = Math::Clamp(SurfacePos.X, 0.0, 1.0);
		SurfacePos.Y = Math::Clamp(SurfacePos.Y, 0.0, 1.0);

		Critter.DestSurfacePosition = SurfacePos;
		Critter.DestRelativePosition = RelativePosFromSurfacePos(SurfacePos);

		FVector Direction = (Critter.DestRelativePosition - Critter.StartRelativePosition).GetSafeNormal();
		Critter.StartRotation = FRotator::MakeFromXZ(Direction, Critter.StartRotation.UpVector);
		Critter.DestRotation = FRotator::MakeFromXZ(Direction, RelativeUpVectorFromSurfacePos(SurfacePos));
		Critter.bIsRunningAway = true;

		Critter.MoveTimer = 0.0;
		Critter.MoveDuration = 0.75;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	// points are in localspace
	FCritterSurfaceMeshSampleData GetPositionsFromSurfacePos(FVector2D p)
	{
		FCritterSurfaceMeshSampleData Result = FCritterSurfaceMeshSampleData();

		if(Points.Num() == 0)
		{
			Result.Valid = false;
			return Result;
		}

		FVector2D Pos = FVector2D(Math::Clamp(p.X, 0.001, 0.999), Math::Clamp(p.Y, 0.001, 0.999));

		// Convert 0-1 position to 0-with / 0-ResolutionY position
		int X    = int(Pos.X * (ResolutionX - 1));
		int Y 	 = int(Pos.Y * (ResolutionY - 1));
		float Xf = Math::Frac(Pos.X * (ResolutionX  - 1));
		float Yf = Math::Frac(Pos.Y * (ResolutionY - 1));
		
		Result.Fraction = FVector2D(Xf, Yf);

		// get four neighbours
		Result.P0 = Points[ X      +  Y      * ResolutionX];
		Result.P1 = Points[ X      + (Y + 1) * ResolutionX];
		Result.P2 = Points[(X + 1) +  Y      * ResolutionX];
		Result.P3 = Points[(X + 1) + (Y + 1) * ResolutionX];
		
		Result.Valid = true;
		return Result;
	}

	FVector RelativePosFromSurfacePos(FVector2D p)
	{
		auto P = GetPositionsFromSurfacePos(p);

		if(!P.Valid)
			return GetActorLocation();

		FVector PP1 = Math::Lerp(P.P0, P.P1, P.Fraction.Y);
		FVector PP0 = Math::Lerp(P.P2, P.P3, P.Fraction.Y);
		FVector Result = Math::Lerp(PP1, PP0, P.Fraction.X);
		return Result;
	}

	FVector WorldPosFromSurfacePos(FVector2D p)
	{
		return ProjectedTransform.TransformPosition(RelativePosFromSurfacePos(p));
	}

	FVector RelativeUpVectorFromSurfacePos(FVector2D p)
	{
		auto P = GetPositionsFromSurfacePos(p);

		if(!P.Valid)
			return FVector(0, 0, 1);
			
		FVector D1 = P.P0 - P.P1;
		FVector D2 = P.P0 - P.P2;

		FVector Result = D2.CrossProduct(D1);
		Result.Normalize();

		return Result;
	}

	FVector WorldUpVectorFromSurfacePos(FVector2D p)
	{
		return ProjectedTransform.TransformVector(RelativeUpVectorFromSurfacePos(p));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = 0; i < NumberOfCritters; i++)
		{
			FCritterSurfaceCritter& Critter = Critters[i];
			Critter.MoveTimer += DeltaTime;

			// Pick a new destination if the current one was reached
			if (Critter.MoveTimer > Critter.MoveDuration)
			{
				CritterReachDestination(Critter);
				MakeNewCritterDestination(Critter);
			}

			// Check if this critter should run away
			if (!Critter.bIsRunningAway && Critter.MeshComp != nullptr)
			{
				// Only check one critter per frame for running away
				if (GFrameNumber % uint(NumberOfCritters) == uint(i))
				{
					float ClosestDist = MAX_flt;
					FVector ClosestPosition;
					for (auto Player : Game::Players)
					{
						FVector PlayerRelativePosition = ActorTransform.InverseTransformPosition(Player.ActorLocation);
						float Distance = PlayerRelativePosition.Distance(Critter.MeshComp.RelativeLocation);
						if (Distance < ClosestDist)
						{
							ClosestDist = Distance;
							ClosestPosition = PlayerRelativePosition;
						}
					}

					if (ClosestDist < PushDistance * (Width + Height) * 0.5)
						CritterRunawayFrom(Critter, ClosestPosition);
				}
			}

			// Update the actual critter mesh
			if (Critter.MeshComp != nullptr)
			{
				float MovePct = Critter.MoveTimer / Critter.MoveDuration;
				Critter.MeshComp.SetRelativeLocationAndRotation(
					Math::Lerp(Critter.StartRelativePosition, Critter.DestRelativePosition, MovePct),
					Math::RInterpConstantTo(
						Critter.MeshComp.RelativeRotation,
						Math::LerpShortestPath(Critter.StartRotation, Critter.DestRotation, MovePct),
						DeltaTime, Critter.bIsRunningAway ? 500.f : 180.f)
				);
			}
		}
	}
}