class AGravityBikeSplineStaticPoliceCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkylineHighwayFloatingComponent FloatingComp;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	USceneComponent LightsRotationPivot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 75000;

	UPROPERTY(Category = "Lights")
	float LightsRotationSpeed = 360.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LightsRotationPivot.AddRelativeRotation(FRotator(0.0, LightsRotationSpeed * DeltaSeconds, 0.0));
	}
};