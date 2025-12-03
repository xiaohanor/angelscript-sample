UCLASS(Abstract)
class AMaxSecurityLaserCutterPathCenter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PathRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMaxSecurityLaserCutterPathPiece> PieceClass;

	int PieceAmount = 54;

	UFUNCTION(CallInEditor)
	void CreatePieces()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			AMaxSecurityLaserCutterPathPiece Piece = Cast<AMaxSecurityLaserCutterPathPiece>(Actor);
			if (Piece != nullptr)
				Actor.DestroyActor();
		}

		AMaxSecurityLaserCutterPathPiece PreviousPiece;
		for (int i = 0; i <= PieceAmount - 1; i++)
		{
			AMaxSecurityLaserCutterPathPiece Piece = SpawnActor(PieceClass, ActorLocation, FRotator(0.0, ActorRotation.Yaw - (i * 5), 0.0));
			Piece.AttachToComponent(PathRoot, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

			if (PreviousPiece != nullptr)
			{
				Piece.BackNeighbor = PreviousPiece;
				PreviousPiece.FrontNeighbor = Piece;
			}

			PreviousPiece = Piece;
		}
	}
}