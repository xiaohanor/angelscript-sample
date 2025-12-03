class ASpaceWalkMovingHookActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotatingPart;

	UPROPERTY(EditAnywhere)
	float RotationSpeed; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotatingPart.AddLocalRotation(FRotator(RotationSpeed,0,0) * DeltaSeconds);
	}
};