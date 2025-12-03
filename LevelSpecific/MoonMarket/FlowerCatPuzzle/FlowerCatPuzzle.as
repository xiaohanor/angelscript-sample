struct FMoonMarketFlowerPuzzleOverlapResult
{
	bool bSuccesfulPlacement = false;
	bool bCorrectColor = false;
	TOptional<int> OverlappedCircleIndex;
	AFlowerCatPuzzlePiece BelongingPiece;
}

struct FMoonMarketFlowerPuzzleOverlapData
{
	FVector FlowerLocation;
	EHazePlayer Player;
	UMoonMarketPlayerFlowerSpawningComponent FlowerComp;
	TArray<int> FlowerIds;
	EMoonMarketFlowerHatType Type;
}


event void FOnFlowerCatPuzzleCompleted();

class AFlowerCatPuzzle : AHazeActor
{
	UPROPERTY()
	FOnFlowerCatPuzzleCompleted OnFlowerCatPuzzleCompleted;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visuals;
	default Visuals.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY()
	UMaterialInterface PuzzlePieceMat;

	UPROPERTY()
	TPerPlayer<FLinearColor> TargetColor;

	UPROPERTY()
	float EmissiveStrength = 3;

	TArray<AFlowerCatPuzzlePiece> PuzzlePieces;
	private int TotalPieces;

	private int CurrentlyActivatedPieces = 0;

	void CheckForOverlap(FMoonMarketFlowerPuzzleOverlapData Data, FMoonMarketFlowerPuzzleOverlapResult& OverlapResult)
	{
		for(auto Piece : PuzzlePieces)
		{
			Piece.CheckForOverlap(Data, OverlapResult);
			
			if(OverlapResult.OverlappedCircleIndex.IsSet())
				break;
		}		
	}

	void EraseFlowers(EHazePlayer Player, FVector EraseLocation, float EraseRadius)
	{
		// for(auto Piece : PuzzlePieces)
		// {
		// 	//Piece.EraseFlowers(Player, EraseLocation, EraseRadius);
		// }
	}

	void AddPiece(AFlowerCatPuzzlePiece Piece)
	{
		TotalPieces++;
		PuzzlePieces.Add(Piece);
	}

	void ActivatePiece(AFlowerCatPuzzlePiece Piece)
	{
		FFlowerPuzzlePieceEffectParams Params;
		Params.Piece = Piece;
		Params.OwnerOfPuzzlePiece = Piece.ColorType == EMoonMarketFlowerHatType::Blue ? Game::Zoe : Game::Mio;
		Params.OwnerOfPuzzlePiece.PlayForceFeedback(ForceFeedback::Default_Medium, this);
		UFlowerCatPuzzleEventHandler::Trigger_OnPuzzlePieceActivated(this, Params);
		CurrentlyActivatedPieces++;

		if(CurrentlyActivatedPieces == TotalPieces)
		{
			UFlowerCatPuzzleEventHandler::Trigger_OnPuzzleComplete(this);
			OnFlowerCatPuzzleCompleted.Broadcast();
		}
	}

	UFUNCTION(DevFunction)
	void Dev_FinishFlowerPuzzle()
	{
		OnFlowerCatPuzzleCompleted.Broadcast();	
	}

	void DeactivatePiece(AFlowerCatPuzzlePiece Piece)
	{
		FFlowerPuzzlePieceEffectParams Params;
		Params.Piece = Piece;
		Params.OwnerOfPuzzlePiece = Piece.ColorType == EMoonMarketFlowerHatType::Blue ? Game::Mio : Game::Zoe;
		UFlowerCatPuzzleEventHandler::Trigger_OnPuzzlePieceDeactivated(this, Params);
		CurrentlyActivatedPieces--;
	}

	bool IsPuzzleSolved() const
	{
		return CurrentlyActivatedPieces == TotalPieces;
	}
};