class AJetskiUnderwaterSquid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	default SetActorHiddenInGame(true);
	default PrimaryActorTick.bStartWithTickEnabled = false;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// FRotator NewRot;
		// FVector PlayerLoc = PlayerToFollow.ActorLocation;
		// FVector ActorLoc = ActorLocation;
		// PlayerLoc.Z = 0.0;
		// ActorLoc.Z = 0.0;
		// NewRot = FVector(PlayerLoc - ActorLoc).ToOrientationRotator();
		//SetActorRotation(NewRot);

		//AddActorLocalOffset(FVector(20000 * DeltaSeconds, 0.0, 0.0));

		MeshRoot.AddLocalOffset(FVector(-20000 * DeltaSeconds, 0.0, 0.0));
	}

	UFUNCTION()
	void StartMovingSquid(AHazePlayerCharacter Player)
	{
		SetActorHiddenInGame(false);

		FRotator NewRot;
		FVector PlayerLoc = FVector(Player.ActorLocation + Player.ActorForwardVector * 20000);
		//FVector PlayerLoc = Player.ActorLocation;
		FVector ActorLoc = ActorLocation;
		PlayerLoc.Z = 0.0;
		ActorLoc.Z = 0.0;
		NewRot = FVector(PlayerLoc - ActorLoc).ToOrientationRotator();
		//SetActorRotation(NewRot);
		SetActorTickEnabled(true);
	}
}