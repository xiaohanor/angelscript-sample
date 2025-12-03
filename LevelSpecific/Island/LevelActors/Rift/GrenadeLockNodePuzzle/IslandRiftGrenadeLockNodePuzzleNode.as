event void FIslandRiftGrenadeLockNodePuzzleNodeMoveEvent(AIslandRiftGrenadeLockNodePuzzleMoverBase Mover);

UCLASS(Abstract)
class AIslandRiftGrenadeLockNodePuzzleNode : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY()
	FIslandRiftGrenadeLockNodePuzzleNodeMoveEvent OnBeginMove;

	UPROPERTY()
	FIslandRiftGrenadeLockNodePuzzleNodeMoveEvent OnEndMove;

	UPROPERTY(BlueprintHidden, VisibleAnywhere, DisplayName = "Movable")
	private AIslandRiftGrenadeLockNodePuzzleMovable Internal_Movable;

	UPROPERTY(BlueprintHidden, VisibleAnywhere)
	AIslandRiftGrenadeLockNodePuzzleMoverBase CurrentMover;

	void SetCurrentMover(AIslandRiftGrenadeLockNodePuzzleMoverBase Mover)
	{
		devCheck(CurrentMover == nullptr, "Tried to set current mover when there is already a mover moving this node");

		CurrentMover = Mover;
		OnBeginMove.Broadcast(Mover);
	}

	void ClearCurrentMover(AIslandRiftGrenadeLockNodePuzzleMoverBase Mover)
	{
		devCheck(CurrentMover != nullptr, "Tried to clear current mover when current mover is already null!");
		devCheck(CurrentMover == Mover, "Another mover tried to clear itself than the current mover");

		CurrentMover = nullptr;
		OnEndMove.Broadcast(Mover);
	}

	void SetMovable(AIslandRiftGrenadeLockNodePuzzleMovable InMovable) property
	{
		if(Internal_Movable != nullptr)
			Internal_Movable.CurrentNode = nullptr;

		Internal_Movable = InMovable;

		if(Internal_Movable != nullptr)
			Internal_Movable.CurrentNode = this;
	}

	AIslandRiftGrenadeLockNodePuzzleMovable GetMovable() const property
	{
		return Internal_Movable;
	}
}