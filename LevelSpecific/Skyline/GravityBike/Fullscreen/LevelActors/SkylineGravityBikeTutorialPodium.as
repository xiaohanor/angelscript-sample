class ASkylineGravityBikeTutorialPodium : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivotComp;

	UPROPERTY(EditInstanceOnly)
	AGravityBikeSplineActor ReleaseSplineActor;

	AGravityBikeSpline GravityBike;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	float RotationSpeed = 20.0;

	float RelativeRotation = -120.0;

	UFUNCTION()
	void StartTutorial()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotationSpeed = Math::Clamp(RelativeRotation * -1, 0.0, 20.0);
		RelativeRotation += RotationSpeed * DeltaSeconds;
		RotationPivotComp.SetRelativeRotation(FRotator(0.0, RelativeRotation, 0.0));
	}
};