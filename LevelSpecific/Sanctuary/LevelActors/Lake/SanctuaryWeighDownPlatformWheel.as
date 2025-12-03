class ASanctuaryWeighDownPlatformWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent WheelPivot;

	UPROPERTY(EditAnywhere)
	ASanctuaryWeighDownPlatform Gate;

	UPROPERTY(EditAnywhere)
	float Radius = 400.0;

	float Distance = 0.0;
	float Rotation = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Distance = -Gate.TranslateComp.RelativeLocation.Z;

		PrintToScreen("Distance: " + Distance);

		Rotation = (Distance / (Radius * PI * 2.0)) * 360.0;

		WheelPivot.RelativeRotation = FRotator(Rotation, 0.0, 0.0);
	}
};