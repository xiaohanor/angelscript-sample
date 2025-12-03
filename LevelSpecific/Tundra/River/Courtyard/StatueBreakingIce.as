class AStatueBreakingIce : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent WholeMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BrokenMesh;

	UFUNCTION()
	void BreakIce()
	{
		WholeMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
		WholeMesh.SetHiddenInGame(true);
		
		BrokenMesh.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		BrokenMesh.SetHiddenInGame(false);
	}
};