UCLASS(Abstract)
class AMaxSecurityLaserCutterPathPiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PieceRoot;

	UPROPERTY(DefaultComponent, Attach = PieceRoot)
	USceneComponent PieceCenter;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> DestroyCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect DestroyForceFeedback;

	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutterPathPiece BackNeighbor;
	UPROPERTY(EditInstanceOnly)
	AMaxSecurityLaserCutterPathPiece FrontNeighbor;

	bool bDestroyed = false;

	float DestroyDelay = 0.15;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Same control side as the laser cutter
		SetActorControlSide(Game::Mio);
	}

	bool IsDestroyed() const
	{
		return bDestroyed;
	}

	void ControlDestroyPiece()
	{
		// Only Control can decide to destroy a piece
		if (!ensure(HasControl()))
			return;

		// Always check IsDestroyed() before calling DestroyPiece()
		if (!ensure(!IsDestroyed()))
			return;

		// First, find all connected pieces to destroy
		TArray<AMaxSecurityLaserCutterPathPiece> ConnectedPiecesToDestroy;
		RecursiveFindConnectedPiecesToDestroy(ConnectedPiecesToDestroy);

		// Then crumb sync destroy them
		CrumbDisablePieces(ConnectedPiecesToDestroy);
	}

	private void RecursiveFindConnectedPiecesToDestroy(TArray<AMaxSecurityLaserCutterPathPiece>& ConnectedPiecesToDestroy)
	{
		if (!ensure(HasControl()))
			return;

		// We have already been found
		if (ConnectedPiecesToDestroy.Contains(this))
			return;

		ConnectedPiecesToDestroy.Add(this);

		if (BackNeighbor != nullptr && !BackNeighbor.IsDestroyed())
		{
			if (BackNeighbor.BackNeighbor == nullptr || BackNeighbor.BackNeighbor.IsDestroyed())
				BackNeighbor.RecursiveFindConnectedPiecesToDestroy(ConnectedPiecesToDestroy);
		}

		if (FrontNeighbor != nullptr && !FrontNeighbor.IsDestroyed())
		{
			if (FrontNeighbor.FrontNeighbor == nullptr || FrontNeighbor.FrontNeighbor.IsDestroyed())
				FrontNeighbor.RecursiveFindConnectedPiecesToDestroy(ConnectedPiecesToDestroy);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDisablePieces(TArray<AMaxSecurityLaserCutterPathPiece> ConnectedPiecesToDestroy)
	{
		for (AMaxSecurityLaserCutterPathPiece Piece : ConnectedPiecesToDestroy)
		{
			// We have somehow already destroyed this piece...
			if (!ensure(!Piece.IsDestroyed()))
				continue;

			Piece.DestroyPiece();
		}
	}

	void DestroyPiece()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(DestroyCamShake, this);
			Player.PlayForceFeedback(DestroyForceFeedback, false, true, this);
		}

		bDestroyed = true;

		Timer::SetTimer(this, n"DelayedDestroy", DestroyDelay);
	}

	UFUNCTION()
	void DelayedDestroy()
	{
		BP_DestroyPiece();

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DestroyPiece() {}
}