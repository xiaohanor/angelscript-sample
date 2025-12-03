class ASkylineBallBossPostChaseBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BlockMesh;
	default BlockMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	// UPROPERTY(DefaultComponent, Attach = BlockMesh)
	// UMoveIntoPlayerShapeComponent BlockShape;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	private FVector StartLoc = FVector::ForwardVector * 3000;

	void ForcePlayersIntoElevator()
	{
		BlockMesh.SetRelativeLocation(StartLoc);
		BlockMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		ActionComp.Duration(0.5, this, n"MoveBlock");
		ActionComp.Event(this, n"UnlikelyTrapKill");
	}
	
	UFUNCTION()
	private void MoveBlock(float Alpha)
	{
		BlockMesh.SetRelativeLocation(Math::Lerp(StartLoc, FVector(), Alpha));
		BlockMesh.AddComponentCollisionBlocker(this);
		BlockMesh.RemoveComponentCollisionBlocker(this);
		// Debug::DrawDebugSolidBox(BlockMesh.WorldLocation, BlockMesh.BoundingBoxExtents, BlockMesh.WorldRotation, ColorDebug::White, 0.0, true);
	}

	UFUNCTION()
	private void UnlikelyTrapKill()
	{
		for (auto Player : Game::Players)
		{
			FVector Diff = Player.ActorLocation - ActorLocation;
			if (ActorForwardVector.DotProduct(Diff) > -50)
				Player.KillPlayer();
		}
	}
};