class ASkylineMallChaseRotatingLightFixture : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotatingRoot;

	UPROPERTY()
	float MinAngle = -20.0;

	UPROPERTY()
	float MaxAngle = 20.0;

	UPROPERTY()
	float RotationDuration = 5.0;

	UPROPERTY(EditAnywhere)
	float StartOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = (Math::Sin((Time::GameTimeSeconds + StartOffset) * PI / RotationDuration) + 1.0) * 0.5;
		RotatingRoot.SetRelativeRotation(FRotator(Math::Lerp(MinAngle, MaxAngle, Alpha), 0.0, 0.0));
	}
};