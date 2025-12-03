class ASummitTopDownManualRotatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlatformRoot;


	UPROPERTY(EditAnywhere)
	float PlatformHoldTime;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent RollAttack;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike PlatformRotation;
	default PlatformRotation.Duration = 1.0;
	default PlatformRotation.Curve.AddDefaultKey(0.0, 0.0);
	default PlatformRotation.Curve.AddDefaultKey(1.0, 1.0);

	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// RollAttack.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		PlatformRotation.BindUpdate(this, n"PlatformUpdate");
		StartRotation = PlatformRoot.RelativeRotation;
	}



	UFUNCTION()
	void PlatformReverse()
	{
			PlatformRotation.ReverseFromEnd();

	}

	// UFUNCTION()
	// private void OnHitByRoll(FRollParams Params)
	// {
	// 	if (!PlatformRotation.IsPlaying())
	// 	{
	// 		Timer::SetTimer(this, n"PlatformTimerFunction", PlatformHoldTime);
	// 		PlatformRotation.Play();
	// 	}
	// }

	UFUNCTION()
	void HitEvent()
	{
		//	Timer::SetTimer(this, n"PlatformTimerFunction", PlatformHoldTime);
			PlatformRotation.PlayFromStart();
	}

	UFUNCTION()
	void PlatformUpdate(float Alpha)
	{
		PlatformRoot.RelativeRotation = FQuat::Slerp(StartRotation.Quaternion(), FRotator(90,0,0).Quaternion(), Alpha).Rotator();
	}

	
}