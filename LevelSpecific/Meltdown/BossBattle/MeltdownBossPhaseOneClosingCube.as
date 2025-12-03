class AMeltdownBossPhaseOneClosingCube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CubeStart;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent CubeEnd;

	UPROPERTY(DefaultComponent, Attach = CubeStart)
	UMeltdownBossCubeGridDisplacementComponent Displacement;

	FVector Start;
	FVector Target;

	FHazeTimeLike CubeLike;
	default CubeLike.Duration = 5;
	default CubeLike.UseSmoothCurveZeroToOne();


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Start = CubeStart.RelativeLocation;

		Target = CubeEnd.RelativeLocation;

		CubeLike.BindUpdate(this, n"OnUpdate");
	}

	UFUNCTION(BlueprintCallable)
	void MoveCube()
	{
		CubeLike.PlayFromStart();
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{	
		CubeStart.SetRelativeLocation(Math::Lerp(Start,Target,CurrentValue));
	}
};