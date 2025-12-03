class ACriclingDragonCamera : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(EditAnywhere)
	TArray<ACriclingDragon> TargetDragons;

	UPROPERTY(EditAnywhere)
	AActor Boss;

	float DistanceFromDragons = 5000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector FocusPoint = (TargetDragons[0].ActorLocation + TargetDragons[1].ActorLocation) / 2.0;
		FocusPoint += FVector::UpVector * 1500.0;
		ActorLocation = FocusPoint;
		FVector DirectionToBoss = (Boss.ActorLocation - FocusPoint).GetSafeNormal();
		ActorLocation -= DirectionToBoss * DistanceFromDragons;
		ActorRotation = DirectionToBoss.Rotation();
	}

	UFUNCTION()
	void ActivateCamera(AHazePlayerCharacter Player, float BlendTime)
	{
		Player.ActivateCamera(CameraComp, BlendTime, this);
	}
};