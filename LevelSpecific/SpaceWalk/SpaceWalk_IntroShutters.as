UCLASS(Abstract)
class ASpaceWalk_IntroShutters : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ShutterMove;
	default ShutterMove.Duration = 20.0;
	default ShutterMove.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	FRotator StartRotation = FRotator(0,0,0);

	UPROPERTY(EditAnywhere)
	FRotator EndRotation = FRotator(0,0,-60);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShutterMove.BindUpdate(this, n"OnUpdate");

		ActorRotation = StartRotation;
	}

	UFUNCTION(BlueprintCallable)
	void StartShutter()
	{
		ShutterMove.PlayFromStart();
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		SetActorRotation(Math::LerpShortestPath(StartRotation,EndRotation,CurrentValue));
	}
};
