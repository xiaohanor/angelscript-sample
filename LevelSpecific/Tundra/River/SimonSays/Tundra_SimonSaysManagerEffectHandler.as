enum ETundra_SimonSaysEffectTileType
{
	None = 0,
	TopLeft = 1,
	TopRight = 2,
	BottomLeft = 3,
	BottomRight = 4
}

struct FTundra_SimonSaysManagerTilesMoveEffectParams
{
	UPROPERTY()
	bool bIsMiddleTiles;
}

struct FTundra_SimonSaysManagerTileMoveEffectParams
{
	UPROPERTY()
	ACongaDanceFloorTile Tile;

	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	FLinearColor TileColor;

	UPROPERTY()
	FLinearColor TileTargetColor;

	UPROPERTY()
	bool bIsMiddleTile;
}

struct FTundra_SimonSaysManagerMonkeyKingTileMoveEffectParams
{
	UPROPERTY()
	ATundra_SimonSaysMonkeyKingTile Tile;
}

struct FTundra_SimonSaysManagerTileGenericEffectParams
{
	UPROPERTY()
	ACongaDanceFloorTile Tile;

	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	ETundra_SimonSaysEffectTileType TileType;

	UPROPERTY()
	FLinearColor TileColor;

	UPROPERTY()
	FLinearColor TileTargetColor;
}

struct FTundra_SimonSaysManagerMonkeyKingTileEffectParams
{
	UPROPERTY()
	ATundra_SimonSaysMonkeyKingTile Tile;

	UPROPERTY()
	ETundra_SimonSaysEffectTileType TileType;

	UPROPERTY()
	FLinearColor TileColor;

	UPROPERTY()
	FLinearColor TileTargetColor;
}

struct FTundra_SimonSaysManagerFailStageEffectParams
{
	UPROPERTY()
	EHazeSelectPlayer FailedPlayers;
}

struct FTundra_SimonSaysManagerOnNextStageEffectParams
{
	UPROPERTY()
	int CurrentStageIndex;
}

struct FTundra_SimonSaysManagerOnPlayerSuccessEffectParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FTundra_SimonSaysMangerOnPlayerPickTargetEffectParams
{
	UPROPERTY()
	UTundra_SimonSaysPerchPointTargetable Targetable;
}

UCLASS(Abstract)
class UTundra_SimonSaysManagerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSimonSaysStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnNextStage(FTundra_SimonSaysManagerOnNextStageEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTilesMoveUp(FTundra_SimonSaysManagerTilesMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTilesMoveDown(FTundra_SimonSaysManagerTilesMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTileMoveUp(FTundra_SimonSaysManagerTileMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTileMoveDown(FTundra_SimonSaysManagerTileMoveEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSuccessfulLand(FTundra_SimonSaysManagerTileGenericEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFailLand(FTundra_SimonSaysManagerTileGenericEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTileWave() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerSuccess(FTundra_SimonSaysManagerOnPlayerSuccessEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSuccessfulStage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFailStage(FTundra_SimonSaysManagerFailStageEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMonkeyKingSuccessfulLand(FTundra_SimonSaysManagerMonkeyKingTileEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCameraStartMovingToMonkeyKing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerPickTarget(FTundra_SimonSaysMangerOnPlayerPickTargetEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerClearTarget() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMonkeyKingTileMoveDown(FTundra_SimonSaysManagerMonkeyKingTileMoveEffectParams Params) {}
}