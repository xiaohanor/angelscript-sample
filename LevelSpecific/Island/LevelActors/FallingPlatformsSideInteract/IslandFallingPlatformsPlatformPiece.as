struct FIslandFallingPlatformsPlatformShapeData
{
	UPROPERTY()
	bool bPiece1_1;

	UPROPERTY()
	bool bPiece1_2;

	UPROPERTY()
	bool bPiece1_3;

	UPROPERTY()
	bool bPiece2_1;

	UPROPERTY()
	bool bPiece2_2;

	UPROPERTY()
	bool bPiece2_3;

	UPROPERTY()
	bool bPiece3_1;

	UPROPERTY()
	bool bPiece3_2;

	UPROPERTY()
	bool bPiece3_3;
}

UCLASS(Abstract)
class AIslandFallingPlatformsPlatformPiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Piece1_1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Piece1_2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Piece1_3;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Piece2_1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Piece2_2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Piece2_3;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Piece3_1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Piece3_2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Piece3_3;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPos;
	default SyncedActorPos.SyncRate = EHazeCrumbSyncRate::High;
	default SyncedActorPos.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly_Imprecise;

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	TArray<UMaterialInterface> Materials;

	UPROPERTY(EditAnywhere)
	FVector Scale = FVector(1.0);

	AIslandFallingPlatformsBoard Board;
	AIslandFallingPlatformsManager Manager;

	UPROPERTY(EditAnywhere)
	float BaseFallingSpeed = 250.0;

	UPROPERTY(EditAnywhere)
	float SpeedUpMultiplier = 5.0;

	UPROPERTY(EditAnywhere)
	float FallingSpeedInAcid = 15.0;

	float HeightExtentOfPiece;
	bool bShouldSpeedUp = false;
	
	const float KillHeightOffset = -1500.0;

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	TArray<UStaticMeshComponent> AllPieces;
	FIslandFallingPlatformsPlatformShapeData CurrentShapeData;
	TArray<UStaticMeshComponent> ActivePieces;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		AllPieces.Reset();
		GetAllPieces(AllPieces);

		for(int i = 0; i < AllPieces.Num(); i++)
		{
			int X = Math::IntegerDivisionTrunc(i, 3);
			int Y = i % 3;
			FVector Offset;
			Offset += FVector::ForwardVector * -(X - 1);
			Offset += FVector::RightVector * (Y - 1);

			UStaticMeshComponent Comp = AllPieces[i];
			Comp.StaticMesh = Mesh;
			for(int j = 0; j < Materials.Num(); j++)
			{
				Comp.SetMaterial(j, Materials[j]);
			}
			Comp.RelativeScale3D = Scale;
			FBox Bounds = Comp.GetBoundingBoxRelativeToOwner();
			Comp.RelativeLocation = Offset * Bounds.Extent * 2.0;
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Board = TListedActors<AIslandFallingPlatformsBoard>().Single;
		Manager = TListedActors<AIslandFallingPlatformsManager>().Single;
		HeightExtentOfPiece = GetActorLocalBoundingBox(true).Extent.Z * ActorScale3D.Z;

		AllPieces.Reset();
		GetAllPieces(AllPieces);

		for(UStaticMeshComponent Piece : AllPieces)
		{
			auto SquishTrigger = USquishTriggerBoxComponent::Create(this);
			SquishTrigger.Polarity = ESquishTriggerBoxPolarity::Universal;
			SquishTrigger.AttachToComponent(Piece);
			SquishTrigger.ResetRelativeTransform();
			FBox Bounds = Piece.GetComponentLocalBoundingBox();
			SquishTrigger.BoxExtent = FVector(Bounds.Extent.X - 5.0, Bounds.Extent.Y - 5.0, Bounds.Extent.Z + 10.0);
		}
	}

	void ApplyShapeData(FIslandFallingPlatformsPlatformShapeData ShapeData)
	{
		ActivePieces.Reset();
		CurrentShapeData = ShapeData;
		SetPieceActive(Piece1_1, ShapeData.bPiece1_1);
		SetPieceActive(Piece1_2, ShapeData.bPiece1_2);
		SetPieceActive(Piece1_3, ShapeData.bPiece1_3);
		SetPieceActive(Piece2_1, ShapeData.bPiece2_1);
		SetPieceActive(Piece2_2, ShapeData.bPiece2_2);
		SetPieceActive(Piece2_3, ShapeData.bPiece2_3);
		SetPieceActive(Piece3_1, ShapeData.bPiece3_1);
		SetPieceActive(Piece3_2, ShapeData.bPiece3_2);
		SetPieceActive(Piece3_3, ShapeData.bPiece3_3);
	}

	private void SetPieceActive(UStaticMeshComponent Piece, bool bActive)
	{
		auto SquishBox = Cast<USquishTriggerBoxComponent>(Piece.GetChildComponentByClass(USquishTriggerBoxComponent));
		SquishBox.bEnabled = bActive;
		if(bActive)
		{
			Piece.RemoveComponentVisualsAndCollisionAndTickBlockers(this);
			ActivePieces.Add(Piece);
		}
		else
		{
			Piece.AddComponentVisualsAndCollisionAndTickBlockers(this);
		}
	}

	void GetAllPieces(TArray<UStaticMeshComponent>&out OutAllPieces)
	{
		OutAllPieces.Add(Piece1_1);
		OutAllPieces.Add(Piece1_2);
		OutAllPieces.Add(Piece1_3);
		OutAllPieces.Add(Piece2_1);
		OutAllPieces.Add(Piece2_2);
		OutAllPieces.Add(Piece2_3);
		OutAllPieces.Add(Piece3_1);
		OutAllPieces.Add(Piece3_2);
		OutAllPieces.Add(Piece3_3);
	}

	void Init(UHazeActorNetworkedSpawnPoolComponent In_SpawnPool)
	{
		RemoveActorDisable(this);
		SpawnPool = In_SpawnPool;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!HasControl())
			return;

		float Gravity = IsInAcid() ? FallingSpeedInAcid : BaseFallingSpeed;
		if(!IsInAcid() && bShouldSpeedUp)
			Gravity *= SpeedUpMultiplier;

		ActorLocation += FVector::DownVector * (Gravity * DeltaTime);

		if(ShouldGetKilled())
			Kill();
	}

	float GetSignedDistanceToAcid() const property
	{
		return (ActorLocation.Z - HeightExtentOfPiece) - WorldHeightOfAcid;
	}

	bool IsInAcid() const
	{
		return SignedDistanceToAcid <= 0.0;
	}

	float GetWorldHeightOfAcid() const property
	{
		return Board.ActorLocation.Z;
	}

	bool ShouldGetKilled()
	{
		if(Board.ActorLocation.Z < WorldHeightOfAcid + KillHeightOffset)
			return true;

		return false;
	}

	void Kill()
	{
		CrumbKill();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbKill()
	{
		AddActorDisable(this);
		SpawnPool.UnSpawn(this);
		bShouldSpeedUp = false;
	}
}