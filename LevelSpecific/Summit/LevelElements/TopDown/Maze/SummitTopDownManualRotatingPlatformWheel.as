class ASummitTopDownManualRotatingPlatformWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformRoot;

	UPROPERTY(EditAnywhere, Category = "Settings")
	ASummitRollingWheel Wheel;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRuntimeFloatCurve RotationCurve;
	default RotationCurve.AddDefaultKey(0.5, 0.0);
	default RotationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationSpeed = 0.0005;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bReverse = false;

	// How much more it should rotate before it reaches its target
	UPROPERTY(EditAnywhere, Category = "Settings")
	FRotator RelativeRotationTarget = FRotator(90, 0, 0);

	FRotator StartRotation;
	FRotator EndRotation;

	float WheelPosition = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Wheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolling");
		StartRotation = PlatformRoot.RelativeRotation;
		EndRotation =  PlatformRoot.RelativeRotation + RelativeRotationTarget;
		if(bReverse)
			PlatformRoot.SetRelativeRotation(EndRotation);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnWheelRolling(float Amount)
	{
		WheelPosition += Amount * RotationSpeed;
		WheelPosition = Math::Clamp(WheelPosition, 0 , 1);
		float Alpha;
		if(bReverse)
			Alpha = 1 - WheelPosition;
		else
			Alpha = WheelPosition;
		float CurveFloat = RotationCurve.GetFloatValue(Alpha);
		PlatformRoot.RelativeRotation = FQuat::Slerp(StartRotation.Quaternion(), EndRotation.Quaternion(), CurveFloat).Rotator();
	}
};