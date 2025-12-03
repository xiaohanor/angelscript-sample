class ARollingSerpent : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	// UPROPERTY(DefaultComponent, Attach = MeshRoot)
	// UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	FRotator CurrentRotation;

	UPROPERTY()
	float RotateAmount = 360.0;

	UPROPERTY()
	float PitchAmount = 90.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentRotation = ActorRotation;
	}

	UFUNCTION()
	void StartRollRotation() 
	{
		BP_BeginRotation();
		for (AHazePlayerCharacter Player : Game::Players)
			Player.AddMovementImpulse((-ActorRightVector * 1000.0) + (ActorUpVector * 1000.0));
	}

	UFUNCTION(BlueprintEvent)
	void BP_BeginRotation() {}

	UFUNCTION()
	void StartPitchRotation() 
	{
		BP_BeginPitching();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BeginPitching() {}

	UFUNCTION()
	void InstantPitchRotation()
	{
		SetActorRotation(FRotator(PitchAmount, 0.0, 0.0));
	}

	UFUNCTION()
	void ReturnPitchRotation() 	
	{
		BP_ReturnPitching();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ReturnPitching() {}
}