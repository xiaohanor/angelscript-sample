UCLASS(Abstract)
class AIslandRiftGrenadeLockNodePuzzleSwapperMover : AIslandRiftGrenadeLockNodePuzzleMoverBase
{
	UPROPERTY(EditAnywhere)
	FVector AxisToRotateAround = FVector(0.0, 0.0, 1.0);

	// These actors will rotate with the nodes.
	UPROPERTY(EditAnywhere)
	TArray<AActor> AdditionalActorsToRotate;

	void ValidateNodes() override
	{
		devCheck(Nodes.Num() == 2, "Amount of nodes was not 2 on swapper mover, this is not supported!");
	}

	AIslandRiftGrenadeLockNodePuzzleNode GetDestinationNodeForMovable(int CurrentNodeIndex) override
	{
		return Nodes[CurrentNodeIndex == 0 ? 1 : 0];
	}

	void MovableMoveTick(FIslandRiftGrenadeLockNodePuzzleMovingMovableData MovableData, float MoveAlpha) override
	{
		float AlphaDelta = MoveAlpha - PreviousMoveAlpha;
		FRotator DeltaRotator = Math::RotatorFromAxisAndAngle(AxisToRotateAround * (bCurrentMoveShouldBeReversed ? -1.0 : 1.0), AlphaDelta * 180.0);

		FVector MoverToMovable = MovableData.Movable.ActorLocation - ActorLocation;
		FVector RotatedMoverToMovable = DeltaRotator.RotateVector(MoverToMovable);
		MovableData.Movable.ActorLocation = ActorLocation + RotatedMoverToMovable;
		MovableData.Movable.ActorRotation = (DeltaRotator.Quaternion() * MovableData.Movable.ActorQuat).Rotator();
	}

	void MoveTick(float MoveAlpha) override
	{
		float AlphaDelta = MoveAlpha - PreviousMoveAlpha;
		FRotator DeltaRotator = Math::RotatorFromAxisAndAngle(AxisToRotateAround * (bCurrentMoveShouldBeReversed ? -1.0 : 1.0), AlphaDelta * 180.0);

		for(int i = 0; i < AdditionalActorsToRotate.Num(); i++)
		{
			AActor Current = AdditionalActorsToRotate[i];
			Current.ActorRotation = (DeltaRotator.Quaternion() * Current.ActorQuat).Rotator();
		}
	}
}