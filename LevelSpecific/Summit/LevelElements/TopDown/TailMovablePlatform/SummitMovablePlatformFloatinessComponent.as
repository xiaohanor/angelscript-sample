class USummitMovablePlatformFloatinessComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	FName FloatComponentName = n"MeshRootComponent";

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRotator FloatRotateMax = FRotator(1.153875, 0.0, 1.51298739187);

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRotator FloatRotateFrequency = FRotator(0.1513652613, 0.0, 0.1198518972);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float HeightFloatMax = 40.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float HeightFloatFrequency = 0.1256123;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartActive = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DelayBeforeFullFloatiness = 1.0;

	USceneComponent FloatRoot;
	
	FRotator StartRelativeRotation;
	FVector StartRelativeLocation;

	float TimeStarted = -MAX_flt;

	bool bIsActive = false;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FloatRoot = Owner.GetComponent(USceneComponent, FloatComponentName);
		if(FloatRoot != nullptr)
		{
			StartRelativeRotation = FloatRoot.RelativeRotation;
			StartRelativeLocation = FloatRoot.RelativeLocation;
		}

		ToggleActive(bStartActive);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(FloatRoot == nullptr)
			return;

		if(!bIsActive)
			return;

		float TimeSinceStarted = Time::GetGameTimeSince(TimeStarted);
		float FloatMultiplier = 1.0;
		if(TimeSinceStarted < DelayBeforeFullFloatiness)
			FloatMultiplier = TimeSinceStarted / DelayBeforeFullFloatiness;

		float SinPitch = Math::Sin(TimeSinceStarted * TWO_PI * FloatRotateFrequency.Pitch) * FloatRotateMax.Pitch * FloatMultiplier;
		float SinRoll = -Math::Sin(TimeSinceStarted * TWO_PI * FloatRotateFrequency.Roll) * FloatRotateMax.Roll * FloatMultiplier;

		FRotator FloatRotation = FRotator(SinPitch, 0.0, SinRoll);
		FloatRoot.RelativeRotation = StartRelativeRotation + FloatRotation;
		
		float SinHeight = Math::Sin(TimeSinceStarted * TWO_PI * HeightFloatFrequency) * HeightFloatMax * FloatMultiplier;
		FloatRoot.RelativeLocation = StartRelativeLocation + Owner.ActorUpVector * SinHeight;
	}

	void ToggleActive(bool bActivate)
	{
		if(bActivate)
			TimeStarted = Time::GameTimeSeconds;

		bIsActive = bActivate;
	}
};