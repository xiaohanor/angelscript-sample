class ASkylineCubeTwister : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TwistPivot;

	FHazeAcceleratedFloat AcceleratedFloat;

	UPROPERTY(EditAnywhere)
	float OffsetTime = 0.0;

	float Delay = 1.2;
	float Speed = 0.8;
	float Angle = 90.0;
	float TwistTime = 0.0;
	float StartAngle = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TwistTime = Time::GlobalCrumbTrailTime + Delay + OffsetTime;
		StartAngle = TwistPivot.RelativeRotation.Roll;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GlobalCrumbTrailTime < TwistTime)
		{
			AcceleratedFloat.AccelerateTo(1.0, Speed, DeltaSeconds);
			float Rotation = AcceleratedFloat.Value * Angle;
			TwistPivot.RelativeRotation = FRotator(0.0, 0.0, StartAngle + Rotation);		
		}

		if (Time::GlobalCrumbTrailTime > TwistTime + Delay)
		{
			AcceleratedFloat.SnapTo(0.0);
			TwistTime = Time::GlobalCrumbTrailTime + Speed;
			StartAngle += Angle;
		}
	}
};