class ACoastTrainDummyRotator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float RotationSpeedX = 40;

	UPROPERTY()
	float RotationSpeedY = 30;

	UPROPERTY()
	float RotationSpeedZ = 60;

	UPROPERTY()
	float SplineDistance = 0;

	UPROPERTY()
	float Speed = 5000;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, ExposeOnSpawn)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere, ExposeOnSpawn)
	FVector OffsetFromSpline;

	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	bool RotateTheActor = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(RotateTheActor)
		{
			FRotator NewRotator = FRotator(RotationSpeedX * DeltaSeconds, RotationSpeedY * DeltaSeconds, RotationSpeedZ * DeltaSeconds);
			SetActorRotation(GetActorQuat() * NewRotator.Quaternion());
		}
		

		SplineDistance += Speed * DeltaSeconds;
		
		FVector NewLocation;
		NewLocation = SplineActor.Spline.GetWorldLocationAtSplineDistance(SplineDistance);
		NewLocation += OffsetFromSpline;

		SetActorLocation(NewLocation);
	}

};