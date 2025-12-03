class AMeltdownScreenWalkWaterLeak : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent EndLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Water;

	FVector StartWater;
	FVector EndWater;

	UPROPERTY()
	FHazeTimeLike WaterMove;
	default WaterMove.Duration = 5.0;
	default WaterMove.UseSmoothCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartWater = Water.RelativeLocation;
		EndWater = EndLocation.RelativeLocation;

		WaterMove.BindUpdate(this, n"OnUpdate");
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Water.SetRelativeLocation(Math::Lerp(StartWater,EndWater,CurrentValue));
	}

};