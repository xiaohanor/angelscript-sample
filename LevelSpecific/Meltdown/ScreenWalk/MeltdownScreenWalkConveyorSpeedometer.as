class AMeltdownScreenWalkConveyorSpeedometer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Arrow;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ArrowTarget01;
	default ArrowTarget01.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ArrowTarget02;
	default ArrowTarget02.SetHiddenInGame(true);

	UPROPERTY()
	FHazeTimeLike MoveArrow;
	default MoveArrow.Duration = 1.0;
	default MoveArrow.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	TArray<AKineticSplineFollowActor> Conveyor;

	UPROPERTY(EditAnywhere)
	TArray<AKineticSplineFollowActor> ConveyorFaster;

	UPROPERTY(EditAnywhere)
	TArray<AKineticSplineFollowActor> ConveyorFastest;

	UPROPERTY()
	float ConveyorSpeed;

	UPROPERTY()
	FRotator CurrentRotation;
	UPROPERTY()
	FRotator TargetRotation;

	UPROPERTY()
	int ArrowMove;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveArrow.BindFinished(this, n"OnFinished");
		MoveArrow.BindUpdate(this, n"OnUpdate");

		CurrentRotation = Arrow.RelativeRotation;
		TargetRotation = ArrowTarget01.RelativeRotation; 

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Arrow.AddLocalRotation(FRotator(0,-800,0) * DeltaSeconds);
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Arrow.SetRelativeRotation(Math::LerpShortestPath(CurrentRotation,TargetRotation, CurrentValue));
	}

	UFUNCTION(BlueprintCallable)
	void UpdateArrow()
	{
		ChangeArrow();
	}

	UFUNCTION(BlueprintCallable)
	void BreakArrow()
	{
		SetActorTickEnabled(true);
		BrokenArrow();
	}

	UFUNCTION(BlueprintEvent)
	void BrokenArrow()
	{}

	UFUNCTION()
	private void OnFinished()
	{
		ArrowMove += 1;
		ArrowDone();
	}

	UFUNCTION(BlueprintEvent)
	void ArrowDone()
	{}

	UFUNCTION(BlueprintEvent)
	void ChangeArrow()
	{}
};