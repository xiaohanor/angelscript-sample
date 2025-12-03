class ASpaceWalkHookActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TetherMesh;

	bool bAttached = false;
	bool bAvailable = true;
	AHazePlayerCharacter Player;
	USpaceWalkPlayerComponent SpaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TetherMesh.SetAbsolute(true, true, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bHidden)
		{
			FVector PlayerLocation = Player.Mesh.GetSocketLocation(SpaceComp.GetHookLaunchSocket());

			TetherMesh.SetHiddenInGame(false);

			FQuat Rotation = FQuat::MakeFromZ(ActorLocation - PlayerLocation);
			FVector Center = (ActorLocation + PlayerLocation) * 0.5;
			FVector Scale = FVector(0.03, 0.03, PlayerLocation.Distance(ActorLocation) / 100.0);

			FTransform TetherTransform = FTransform(Rotation, Center, Scale);
			TetherMesh.SetWorldTransform(TetherTransform);

			// Debug::DrawDebugLine(
			// 	ActorLocation, TargetLocation,
			// 	FLinearColor(0.1, 0.1, 0.1), 20.0, 0.0
			// );
		}
		else
		{
			TetherMesh.SetHiddenInGame(true);
		}
	}
};