class ASerpentArmor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPlayerInheritMovementComponent InheritComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent RespawnLocation;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent WeakpointLocation;

	bool bRespawnPointAttached;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bRespawnPointAttached)
			Debug::DrawDebugSphere(RespawnLocation.WorldLocation, 1000.0, 16, FLinearColor::Green, 150.0);
	}

	void AttachRespawnPoint(ARespawnPoint RespawnPoint)
	{
		RespawnPoint.AttachToComponent(RespawnLocation);
		// bRespawnPointAttached = true;
	}

	void AttachWeakpoint(AStoneBossWeakpointCover Weakpoint)
	{
		Weakpoint.AttachToComponent(WeakpointLocation);	
	}
}