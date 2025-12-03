class ATundra_IcePalace_CrackedWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BrokenMesh;
	default BrokenMesh.bHiddenInGame = true;
	default BrokenMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	FHazeTimeLike MoveWallUpTimelike;
	default MoveWallUpTimelike.Duration = 1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Arrow;

	FVector StartingLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveWallUpTimelike.BindUpdate(this, n"MoveWallUpTimelikeUpdate");
		MoveWallUpTimelike.BindFinished(this, n"MoveWallUpTimelikeFinished");

		StartingLoc = ActorLocation;
	}

	UFUNCTION()
	void MoveWallUp()
	{
		MoveWallUpTimelike.PlayFromStart();
		UTundra_IcePalace_CrackedWallEffectHandler::Trigger_OnOpenGate(this);
	}

	UFUNCTION()
	private void MoveWallUpTimelikeUpdate(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(StartingLoc, StartingLoc + FVector(0, 0, 600), CurrentValue));
	}

	UFUNCTION()
	private void MoveWallUpTimelikeFinished()
	{
	
	}

	UFUNCTION()
	void BreakWall()
	{
		Mesh.SetHiddenInGame(true);
		Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		BrokenMesh.SetHiddenInGame(false);
		BrokenMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}
};