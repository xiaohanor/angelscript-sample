class ATiltingWorldActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent)
    UTiltingWorldResponseComponent TiltingWorldResponseComp;

	FRotator StartRotation;

	UPROPERTY(EditAnywhere)
	bool bAccelerateToRotation = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bAccelerateToRotation"))
	float Acceleration = 2.0;

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = GetActorRotation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FRotator TargetRotation = StartRotation.Compose(TiltingWorldResponseComp.GetWorldRotation());

		if(bAccelerateToRotation)
		{
			AccRotation.AccelerateTo(TargetRotation, 1.0 / Acceleration, DeltaSeconds);
			SetActorRotation(AccRotation.Value);
		}
		else
		{
			SetActorRotation(TargetRotation);
		}
	}
}