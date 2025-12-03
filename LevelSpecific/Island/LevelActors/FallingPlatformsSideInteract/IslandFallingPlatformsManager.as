struct FIslandFallingPlatformsTelegraphDecalsArray
{
	TArray<AIslandFallingPlatformsTelegraphDecal> Decals;
}

UCLASS(Abstract)
class AIslandFallingPlatformsManager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent EditorBillboard;
	default EditorBillboard.SetSpriteName("S_Player");
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AIslandFallingPlatformsPlatformPiece> PlatformPieceClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AIslandFallingPlatformsObstacle> ObstacleClass;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AIslandFallingPlatformsTelegraphDecal> TelegraphDecalClass;

	UPROPERTY(EditAnywhere)
	TArray<FIslandFallingPlatformsPlatformShapeData> ShapeData;

	UPROPERTY(EditInstanceOnly)
	AIslandFallingPlatformsInteractionTerminal Terminal;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor Camera;

	UPROPERTY(EditInstanceOnly)
	float CameraBlendInTime = 2.0;

	TArray<AIslandFallingPlatformsForceField> ForceFields;
	AHazePlayerCharacter InteractingPlayer;
	AIslandFallingPlatformsPlatformPiece CurrentPlatform;
	private TArray<AIslandFallingPlatformsTelegraphDecal> TelegraphDecals;
	private AIslandFallingPlatformsBoard Board;
	private TMap<FInstigator, FIslandFallingPlatformsTelegraphDecalsArray> ActiveDecals;
	private bool bActive = false;
	private UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	private FIslandFallingPlatformsPlatformShapeData CurrentShapeData;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		auto TempBoard = TListedActors<AIslandFallingPlatformsBoard>().Single;
		ActorLocation = FVector(TempBoard.ActorLocation.X, TempBoard.ActorLocation.Y, ActorLocation.Z);
		ActorRotation = TempBoard.ActorRotation;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Board = TListedActors<AIslandFallingPlatformsBoard>().Single;
		Terminal.InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnStartInteract");
		Terminal.InteractionComp.OnInteractionStopped.AddUFunction(this, n"OnStopInteract");
		SpawnTelegraphDecal();
		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(PlatformPieceClass, this);
		SpawnPool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSpawned");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		devCheck(bActive);

		if(!HasControl())
			return;

		if(ShouldSpawn())
			Spawn();
	}

	private bool ShouldSpawn()
	{
		if(CurrentPlatform == nullptr)
			return true;

		if(CurrentPlatform.IsInAcid())
			return true;

		return false;
	}

	private void SpawnTelegraphDecal()
	{
		for(int X = -Board.BoardExtents; X <= Board.BoardExtents; X++)
		{
			for(int Y = -Board.BoardExtents; Y <= Board.BoardExtents; Y++)
			{
				FIslandGridPoint GridPoint(X, Y);
				FVector Location = Board.GetWorldLocationOfGridPoint(GridPoint);
				AIslandFallingPlatformsTelegraphDecal Decal = SpawnActor(TelegraphDecalClass, Location);
				Decal.AddActorDisable(this);
				TelegraphDecals.Add(Decal);
			}
		}
	}

	private void Spawn()
	{
		FIslandGridPoint Point = GetGridPointToSpawnOn();
		CrumbSetCurrentShapeData(ShapeData[Math::RandRange(0, ShapeData.Num() - 1)]);
		FRotator LocalRotation = FRotator(0.0, 90.0 * Math::RandRange(0, 3), 0.0);

		FVector WorldLocation = Board.GetWorldLocationOfGridPoint(Point);
		WorldLocation.Z = ActorLocation.Z;
		FRotator Rotation = ActorTransform.TransformRotation(LocalRotation);

		FHazeActorSpawnParameters Params;
		Params.Location = WorldLocation;
		Params.Rotation = Rotation;
		Params.Spawner = this;
		ClearActiveTelegraphDecals(CurrentPlatform);
		CurrentPlatform = Cast<AIslandFallingPlatformsPlatformPiece>(SpawnPool.SpawnControl(Params));
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetCurrentShapeData(FIslandFallingPlatformsPlatformShapeData In_CurrentShapeData)
	{
		CurrentShapeData = In_CurrentShapeData;
	}

	UFUNCTION()
	private void OnSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		auto Platform = Cast<AIslandFallingPlatformsPlatformPiece>(SpawnedActor);
		Platform.ApplyShapeData(CurrentShapeData);
		Platform.Init(SpawnPool);

		UpdateTelegraphDecals(Platform);
	}

	private void UpdateTelegraphDecals(AIslandFallingPlatformsPlatformPiece Platform)
	{
		ClearActiveTelegraphDecals(Platform);
		for(UStaticMeshComponent Piece : Platform.ActivePieces)
		{
			FIslandGridPoint GridPoint = Board.GetClosestGridPoint(Piece.WorldLocation);
			AddTelegraphDecalActiveInstigator(GridPoint, Platform);
		}
	}

	private FIslandGridPoint GetGridPointToSpawnOn() const
	{
		FIslandGridPoint GridPoint = Board.GetClosestGridPoint(InteractingPlayer.OtherPlayer.ActorLocation);
		FIslandGridPoint EdgeNormal;
		if(Board.IsGridPointOnEdge(GridPoint, EdgeNormal))
			GridPoint -= EdgeNormal;

		TArray<FIslandGridPoint> AdjacentGridPoints;
		Board.GetAdjacentGridPoints(GridPoint, AdjacentGridPoints);
		AdjacentGridPoints.Add(GridPoint);

		for(FIslandGridPoint Point : AdjacentGridPoints)
		{
			if(Board.IsAdjacentGridPointBlocked(Point))
				continue;

			if(Board.IsGridPointOnEdge(Point))
				continue;

			return Point;
		}

		devError("This shouldn't happen, didn't find any valid spawn points");
		return FIslandGridPoint();
	}

	void AddTelegraphDecalActiveInstigator(FIslandGridPoint GridPoint, FInstigator Instigator)
	{
		AIslandFallingPlatformsTelegraphDecal Decal = GetTelegraphDecal(GridPoint);
		ActiveDecals.FindOrAdd(Instigator).Decals.AddUnique(Decal);
		Decal.RemoveActorDisable(this);
	}

	void ClearActiveTelegraphDecals(FInstigator Instigator)
	{
		FIslandFallingPlatformsTelegraphDecalsArray& Decals = ActiveDecals.FindOrAdd(Instigator);
		for(AIslandFallingPlatformsTelegraphDecal Decal : Decals.Decals)
		{
			Decal.AddActorDisable(this);
		}

		ActiveDecals.Remove(Instigator);
	}

	AIslandFallingPlatformsTelegraphDecal GetTelegraphDecal(FIslandGridPoint GridPoint)
	{
		FIslandGridPoint ActualGridPoint = GridPoint + FIslandGridPoint(Board.BoardExtents);
		
		return TelegraphDecals[ActualGridPoint.X * Board.BoardGridPointSize + ActualGridPoint.Y];
	}

	// Tries to move the current platform in the specified direction (relative to the managers rotation), returns true if successful!
	bool TryMove(FVector2D LocalDirection)
	{
		if(!HasControl())
			return false;

		if(CurrentPlatform == nullptr)
			return false;

		if(CurrentPlatform.IsInAcid())
			return false;

		if(!CanMovePlatformInDirection(CurrentPlatform, LocalDirection))
			return false;

		FVector Direction = FVector(LocalDirection.X, LocalDirection.Y, 0.0);
		Direction = ActorTransform.TransformVector(Direction);
		CurrentPlatform.ActorLocation += Direction * Board.GridPointSize;
		UpdateTelegraphDecals(CurrentPlatform);
		return true;
	}

	// Tries to rotate the platform in the specified direction, returns true if successful!
	bool TryRotate(bool bClockwise)
	{
		if(!HasControl())
			return false;

		if(CurrentPlatform == nullptr)
			return false;

		if(CurrentPlatform.IsInAcid())
			return false;

		FTransform Transform;
		if(!CanRotatePlatform(CurrentPlatform, bClockwise, Transform))
			return false;

		CurrentPlatform.ActorTransform = Transform;
		UpdateTelegraphDecals(CurrentPlatform);
		return true;
	}

	private bool CanRotatePlatform(AIslandFallingPlatformsPlatformPiece Platform, bool bClockwise, FTransform&out OutTransform) const
	{
		OutTransform = Platform.ActorTransform;
		OutTransform.Rotation = FRotator(0.0, 90.0 * (bClockwise ? 1.0 : -1.0), 0.0).Quaternion() * OutTransform.Rotation;

		for(UStaticMeshComponent Piece : Platform.ActivePieces)
		{
			FVector NewWorldLocation = OutTransform.TransformPosition(Piece.RelativeLocation);
			FIslandGridPoint NewPieceGridPoint = Board.GetClosestGridPoint(NewWorldLocation);

			if(!Board.IsGridPointWithinGrid(NewPieceGridPoint))
				return false;

			if(Board.IsGridPointBlocked(NewPieceGridPoint))
				return false;
		}

		return true;
	}

	private bool CanMovePlatformInDirection(AIslandFallingPlatformsPlatformPiece Platform, FVector2D Direction) const
	{
		FIslandGridPoint GridDirection = Direction;

		for(UStaticMeshComponent Piece : Platform.ActivePieces)
		{
			FIslandGridPoint PieceGridPoint = Board.GetClosestGridPoint(Piece.WorldLocation);
			PieceGridPoint += GridDirection;
			if(!Board.IsGridPointWithinGrid(PieceGridPoint))
				return false;

			if(Board.IsGridPointBlocked(PieceGridPoint))
				return false;
		}

		return true;
	}

	UFUNCTION()
	private void OnStartInteract(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		Player.ActivateCamera(Camera, CameraBlendInTime, this, EHazeCameraPriority::High);
		SetActorTickEnabled(true);
		InteractingPlayer = Player;
		bActive = true;

		for(auto ForceField : ForceFields)
		{
			ForceField.SetForceFieldType(Player.IsMio() ? EIslandRedBlueShieldType::Blue : EIslandRedBlueShieldType::Red);
			ForceField.SetForceFieldActive(true);
		}
	}

	UFUNCTION()
	private void OnStopInteract(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		Player.DeactivateCameraByInstigator(this);
		SetActorTickEnabled(false);
		InteractingPlayer = nullptr;
		bActive = false;

		for(auto ForceField : ForceFields)
		{
			ForceField.SetForceFieldActive(false);
		}
	}
}