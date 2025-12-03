class AStoneBossFinale : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	FRotator CurrentRotation;

	UPROPERTY()
	float RotateAmount = 360.0;

	UPROPERTY()
	float PitchAmount = 90.0;

	float RollTarget;
	float RotationSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentRotation = ActorRotation;
		RollTarget = CurrentRotation.Roll;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorRotation = Math::QInterpConstantTo(ActorRotation.Quaternion(), FRotator(CurrentRotation.Pitch, CurrentRotation.Roll, RollTarget).Quaternion(), DeltaSeconds, RotationSpeed).Rotator();
	}
	
	UFUNCTION()
	void SetRollRotationTarget(float NewRollTarget, float NewRotationSpeed)
	{
		RollTarget = NewRollTarget;
		RotationSpeed = NewRotationSpeed;
	}

	UFUNCTION()
	void StartRollRotation() 
	{
		BP_BeginRotation();
		for (AHazePlayerCharacter Player : Game::Players)
			Player.AddMovementImpulse((-ActorRightVector * 1000.0) + (ActorUpVector * 1000.0));
	}

	//Rolling functionality should go into capabilities
	//Rolling and all movement should be animation driven
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
};