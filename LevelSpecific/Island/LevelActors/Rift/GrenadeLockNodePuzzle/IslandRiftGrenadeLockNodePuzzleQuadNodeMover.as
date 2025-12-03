UCLASS(Abstract)
class AIslandRiftGrenadeLockNodePuzzleQuadNodeMover : AIslandRiftGrenadeLockNodePuzzleMoverBase
{
	UPROPERTY(EditAnywhere)
	bool bReverseMovementDirection = false;

	AIslandRiftGrenadeLockNodePuzzleNode GetDestinationNodeForMovable(int CurrentNodeIndex) override
	{
		if(bReverseMovementDirection != bCurrentMoveShouldBeReversed)
			return Nodes[Math::WrapIndex(CurrentNodeIndex - 1, 0, Nodes.Num())];
		else
			return Nodes[Math::WrapIndex(CurrentNodeIndex + 1, 0, Nodes.Num())];
	}

	void MovableMoveTick(FIslandRiftGrenadeLockNodePuzzleMovingMovableData MovableData, float MoveAlpha) override
	{
		MovableData.Movable.ActorLocation = Math::Lerp(MovableData.FromNode.ActorLocation, MovableData.ToNode.ActorLocation, MoveAlpha);
	}
}