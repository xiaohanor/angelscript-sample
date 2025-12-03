struct FFlowerPuzzlePieceEffectParams
{
	AFlowerCatPuzzlePiece Piece;
	AHazePlayerCharacter OwnerOfPuzzlePiece;
}

UCLASS(Abstract)
class UFlowerCatPuzzleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPuzzlePieceActivated(FFlowerPuzzlePieceEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPuzzlePieceDeactivated(FFlowerPuzzlePieceEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPuzzleComplete() {}
};