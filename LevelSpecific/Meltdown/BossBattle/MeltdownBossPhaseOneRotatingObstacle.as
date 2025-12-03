class AMeltdownBossPhaseOneRotatingObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;
	default Arrow.SetRelativeScale3D(FVector(5.0));

	UPROPERTY(DefaultComponent)
	UBoxComponent KillBox;
	
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	AMeltdownBossCubeGrid Grid;

	UPROPERTY(EditAnywhere)
	float Speed = 2500.0;

	FVector InitialLocation;
	FQuat InitialRotation;

	float MinX = 0.0;
	float MaxX = 500.0;
	
	float MinZ = -100.0;
	float MaxZ = 0.0;

	int CurrentSide = 0;
	float CurX = 0.0;
	float CurZ = 0.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FBox GridBox = Grid.GetActorLocalBoundingBox(true);
		GridBox.Max.Z -= 200.0;

		FVector LocalForward = Grid.ActorTransform.InverseTransformVector(ActorForwardVector).GetSafeNormal();
		FVector LocalSide = FVector::UpVector.CrossProduct(LocalForward).GetSafeNormal();
		FVector LocalInitial = Grid.ActorTransform.InverseTransformPosition(ActorLocation);

		float GridMinX = LocalForward.DotProduct(GridBox.Min);
		float GridMaxX = LocalForward.DotProduct(GridBox.Max);

		FVector WorldTopLeft = Grid.ActorTransform.TransformPosition(
			LocalForward * GridMinX + FVector::UpVector * GridBox.Min.Z + LocalInitial.ConstrainToDirection(LocalSide),
		);
		FVector WorldBotRight = Grid.ActorTransform.TransformPosition(
			LocalForward * GridMaxX + FVector::UpVector * GridBox.Max.Z + LocalInitial.ConstrainToDirection(LocalSide),
		);

		float LocalMinX = ActorTransform.InverseTransformPosition(WorldTopLeft).X;
		float LocalMaxX = ActorTransform.InverseTransformPosition(WorldBotRight).X;

		float LocalMinZ = ActorTransform.InverseTransformPosition(WorldTopLeft).Z;
		float LocalMaxZ = ActorTransform.InverseTransformPosition(WorldBotRight).Z;

		MinX = Math::Min(LocalMinX, LocalMaxX);
		MaxX = Math::Max(LocalMinX, LocalMaxX);

		MinZ = Math::Min(LocalMinZ, LocalMaxZ);
		MaxZ = Math::Max(LocalMinZ, LocalMaxZ);

		CurX = 0.0;
		CurZ = MaxZ;

		InitialLocation = ActorLocation;
		InitialRotation = FQuat::MakeFromZX(Grid.ActorUpVector, ActorForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		FQuat WantedRotation;
		switch (CurrentSide)
		{
			case 0:
				CurX += DeltaSeconds * Speed;
				WantedRotation = InitialRotation;
				if (CurX >= MaxX)
				{
					CurrentSide = 1;
					CurX = MaxX;
				}
			break;
			case 1:
				CurZ -= DeltaSeconds * Speed;
				WantedRotation = InitialRotation * FQuat(FVector::RightVector, 0.5 * PI);
				if (CurZ <= MinZ)
				{
					CurrentSide = 2;
					CurZ = MinZ;
				}
			break;
			case 2:
				CurX -= DeltaSeconds * Speed;
				WantedRotation = InitialRotation * FQuat(FVector::RightVector, PI);
				if (CurX <= MinX)
				{
					CurrentSide = 3;
					CurX = MinX;
				}
			break;
			case 3:
				WantedRotation = InitialRotation * FQuat(FVector::RightVector, 1.5 * PI);
				CurZ += DeltaSeconds * Speed;
				if (CurZ >= MaxZ)
				{
					CurrentSide = 0;
					CurZ = MaxZ;
				}
			break;
		}

		ActorLocation = InitialLocation + InitialRotation.ForwardVector* CurX + InitialRotation.UpVector * CurZ;
		ActorRotation = Math::RInterpConstantShortestPathTo(
			ActorRotation,
			WantedRotation.Rotator(),
			DeltaSeconds, 360.0,
		);

		FHazeShapeSettings KillBoxShape = FHazeShapeSettings::MakeBox(KillBox.BoxExtent);
		for (auto Player : Game::Players)
		{
			if (KillBoxShape.IsPointInside(KillBox.WorldTransform, Player.ActorLocation))
			{
				Player.KillPlayer();
			}
		}
	}
};