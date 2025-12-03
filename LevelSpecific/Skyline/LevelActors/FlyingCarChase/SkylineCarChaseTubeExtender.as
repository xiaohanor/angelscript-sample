class ASkylineCarChaseTubeExtender : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent TubeRoot1;

	UPROPERTY(DefaultComponent, Attach = TubeRoot1)
	USceneComponent TubeRoot2;

	UPROPERTY(DefaultComponent, Attach = TubeRoot2)
	USceneComponent TubeRoot3;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;

	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	UPROPERTY(EditAnywhere)
	AActorTrigger ActorTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorTrigger.OnActorEnter.AddUFunction(this, n"HandleOnCarEnter");
	}

	UFUNCTION()
	private void HandleOnCarEnter(AHazeActor Actor)
	{
		auto FlyingCar = Cast<ASkylineFlyingCar>(Actor);
		if (FlyingCar == nullptr)
			return;
		
		ActionQueComp.Duration(2, this, n"UpdateTubeExtend1");
		ActionQueComp.Event(this, n"EventConstrainHit");
		ActionQueComp.Idle(0.4);
		ActionQueComp.Duration(2, this, n"UpdateTubeExtend2");
		ActionQueComp.Event(this, n"EventConstrainHit");
		ActionQueComp.Idle(0.4);
		ActionQueComp.Duration(2, this, n"UpdateTubeExtend3");
		ActionQueComp.Event(this, n"EventConstrainHit");
		ActionQueComp.Idle(0.4);
	}

	UFUNCTION()
	private void UpdateTubeExtend3(float Alpha)
	{
		TubeRoot3.SetRelativeLocation(FVector (Math::Lerp(0.0, 6500, Alpha), 0.0, 0.0));
	}

	UFUNCTION()
	private void UpdateTubeExtend2(float Alpha)
	{
		TubeRoot2.SetRelativeLocation(FVector (Math::Lerp(0.0, 6500, Alpha), 0.0, 0.0));
	}

	UFUNCTION()
	private void EventConstrainHit()
	{
	}

	UFUNCTION()
	private void UpdateTubeExtend1(float Alpha)
	{
		TubeRoot1.SetRelativeLocation(FVector (Math::Lerp(0.0, 6500, Alpha), 0.0, 0.0));
	}
};