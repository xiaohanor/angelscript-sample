class ASummitWheelRotatingPlatforms : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Platform1;
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Platform2;
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Platform3;
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Platform4;

	float TargetRotateSpeed = 25.0;
	float CurrentRotateSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CurrentRotateSpeed < TargetRotateSpeed)
			CurrentRotateSpeed = Math::FInterpConstantTo(CurrentRotateSpeed, TargetRotateSpeed, DeltaSeconds, TargetRotateSpeed / 3);
		
		AddActorLocalRotation(FRotator(0, 0, -CurrentRotateSpeed * DeltaSeconds));
		Platform1.WorldRotation = FRotator(0);
		Platform2.WorldRotation = FRotator(0);
		Platform3.WorldRotation = FRotator(0);
		Platform4.WorldRotation = FRotator(0);
	}

	void ActivateRotatingPlatforms()
	{
		SetActorTickEnabled(true);
	}
};