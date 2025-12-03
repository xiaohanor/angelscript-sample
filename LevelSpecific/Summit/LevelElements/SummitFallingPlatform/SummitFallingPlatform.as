event void FSummitFallingPlatformSignature();

enum ESummitFallingPlatformState
{
	Walkable,
	Shaking,
	Falling,
	Fallen,
	Resetting,
	None
};
class ASummitFallingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UBoxComponent TriggerBox;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRuntimeFloatCurve ShakeCurve;
	default ShakeCurve.AddDefaultKey(0,0);
	default ShakeCurve.AddDefaultKey(0.5, 0);
	default ShakeCurve.AddDefaultKey(1, 1);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ShakeMaxMagnitude = 30;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ShakeDuration = 3.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotateDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ResetDelay = 2.0;

	private float Timer = 0.0;
	private ESummitFallingPlatformState State;
	private FVector StartRelativeLocation;
	private FRotator StartRotation;
	private FRotator TargetRotation;

	UPROPERTY()
	FSummitFallingPlatformSignature OnShaking;

	UPROPERTY()
	FSummitFallingPlatformSignature OnFall;

	UPROPERTY()
	FSummitFallingPlatformSignature OnReset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		State = ESummitFallingPlatformState::Walkable;

		StartRelativeLocation = Mesh.RelativeLocation;
		StartRotation = RotationRoot.WorldRotation;
		TargetRotation = StartRotation + FRotator(0, 0, 90);
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if(!OtherActor.IsA(AHazePlayerCharacter))
			return;
		
		if(State != ESummitFallingPlatformState::Walkable)
			return;
		
		SetNewState(ESummitFallingPlatformState::Shaking);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;

		ESummitFallingPlatformState NextState = ESummitFallingPlatformState::None;

		if(State == ESummitFallingPlatformState::Shaking)
		{
			Shake();
			if(Timer >= ShakeDuration)
				NextState = ESummitFallingPlatformState::Falling;
		}
		else if(State == ESummitFallingPlatformState::Falling)
		{
			Fall();
			if(Timer >= RotateDuration)
				NextState = ESummitFallingPlatformState::Fallen;
		}
		else if(State == ESummitFallingPlatformState::Fallen)
		{
			if(Timer >= ResetDelay)
				NextState = ESummitFallingPlatformState::Resetting;
		}
		else if(State == ESummitFallingPlatformState::Resetting)
		{
			Reset();
			if(Timer >= RotateDuration)
				NextState = ESummitFallingPlatformState::Walkable;
		}


		if(NextState != ESummitFallingPlatformState::None)
			SetNewState(NextState);
	}

	private void Shake()
	{
		float CurveMultiplier = ShakeCurve.GetFloatValue(Timer/ShakeDuration);
		float ShakeAmount = Math::Cos(Time::GetGameTimeSeconds() * 50) * CurveMultiplier * ShakeMaxMagnitude;
		FVector ShakeOffset = FVector(ShakeAmount, -ShakeAmount, 0);
		FVector NewRelativeLocation = StartRelativeLocation + ShakeOffset;
		Mesh.SetRelativeLocation(NewRelativeLocation);
		OnShaking.Broadcast();
	}

	private void Fall()
	{
		float FallAlpha = Timer / RotateDuration;
		FallAlpha = Math::Clamp(FallAlpha, 0, 1);

		// FRotator NewRotation = FQuat::Slerp(StartRotation.Quaternion(), TargetRotation.Quaternion(), FallAlpha).Rotator();
		// RotationRoot.SetWorldRotation(NewRotation);
		OnFall.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void Reset()
	{
		float FallAlpha = Timer / RotateDuration;
		FallAlpha = Math::Clamp(FallAlpha, 0, 1);

		// FRotator NewRotation = FQuat::Slerp(TargetRotation.Quaternion(), StartRotation.Quaternion(), FallAlpha).Rotator();
		// RotationRoot.SetWorldRotation(NewRotation);
		OnReset.Broadcast();
	}

	private void SetNewState(ESummitFallingPlatformState NewState)
	{
		State = NewState;
		Timer = 0.0;
	}
};