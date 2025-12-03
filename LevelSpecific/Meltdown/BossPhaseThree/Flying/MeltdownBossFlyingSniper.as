class AMeltdownBossFlyingSniper : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LaserObjectMesh;

	UPROPERTY(DefaultComponent, Attach = LaserObjectMesh)
	UStaticMeshComponent Laser;

	FHazeAcceleratedQuat AccRotation;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void Launch (AHazePlayerCharacter PlayerTarget)
	{
		RemoveActorDisable(this);
		Player = PlayerTarget;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		FQuat TargetQuat = (Player.ActorLocation - ActorLocation).GetSafeNormal().VectorPlaneProject(FVector::UpVector).ToOrientationQuat();
		

		AccRotation.AccelerateTo(TargetQuat, 1.0, DeltaSeconds);
		SetActorRotation(AccRotation.Value);
	}
};