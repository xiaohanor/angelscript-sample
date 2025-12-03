class AMeltdownScreenWalkConveyorManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Manager;

	UPROPERTY(EditAnywhere)
	TArray<AMeltdownScreenWalkConveyorObstacle02Main> BreakableObstacles;

	UPROPERTY(EditAnywhere)
	TArray<AMeltdownScreenWalkConveyorObstacle02Alt> RegularObstacles;

	UPROPERTY(EditAnywhere)
	float Speed = 200;

	UPROPERTY(EditAnywhere)
	float AlternateSpeed = 200;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void StartObstacles()
	{
		RunForLoops();
	}

	UFUNCTION(BlueprintEvent)
	void RunForLoops ()
	{}
};