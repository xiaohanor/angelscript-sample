UCLASS(Abstract)
class AIslandRiftGrenadeLockNodePuzzleMovable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	AIslandRiftGrenadeLockNodePuzzleNode CurrentNode;
	bool bHasSnappedMovableToNode = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SnapMovableToClosestNode();
	}

	void SnapMovableToClosestNode()
	{
		TListedActors<AIslandRiftGrenadeLockNodePuzzleNode> Nodes;
		AIslandRiftGrenadeLockNodePuzzleNode ClosestNode;
		float ClosestSqrDistance = MAX_flt;
		for(AIslandRiftGrenadeLockNodePuzzleNode Node : Nodes)
		{
			float SqrDist = Node.ActorLocation.DistSquared(ActorLocation);
			
			if(SqrDist < ClosestSqrDistance)
			{
				ClosestNode = Node;
				ClosestSqrDistance = SqrDist;
			}
		}

		ActorLocation = ClosestNode.ActorLocation;
		ClosestNode.Movable = this;

		bHasSnappedMovableToNode = true;
	}
}