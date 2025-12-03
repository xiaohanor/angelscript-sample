class UAnimInstanceSkylineCar : UHazeAnimInstanceBase
{

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UAnimSequence Animation;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	FRotator WheelRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	FRotator WheelAxisRotationVar1;

	UPROPERTY(BlueprintReadOnly, NotEditable, Transient)
	FRotator WheelAxisRotationVar2;

	FRotator WheelAxisRotationTarget = FRotator(-20, 0, -30);

	FHazeAcceleratedFloat AccFloatVar1;
	FHazeAcceleratedFloat AccFloatVar2;

	float NewRotationTarget = 0;

	float RotationTargetVar1 = 0;
	float RotationTargetVar2 = 0;

	const float START_MOVING_DELAY = 0.35; // Delay before the wheels should start rotating after the car has started moving

	bool bIsMovingActor = false;

	FTimerHandle MoveWheelsDelayTimer;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		auto CarPlatform = Cast<ASkylineCarPlatform>(HazeOwningActor);
		if (CarPlatform != nullptr)
		{
			WheelAxisRotationTarget = CarPlatform.AnimWheelRotation;
			Animation = CarPlatform.Animation;
		}

		if (HazeOwningActor.AttachmentRootActor != nullptr)
		{
			auto KineticMovingActor = Cast<AKineticMovingActor>(HazeOwningActor.AttachmentRootActor);
			if (KineticMovingActor != nullptr)
			{
				bIsMovingActor = true;
				KineticMovingActor.OnStartForward.AddUFunction(this, n"HandleStartForward");
				KineticMovingActor.OnStartBackward.AddUFunction(this, n"HandleStartBackward");
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if (bIsMovingActor)
		{
			RotationTargetVar1 = Math::FInterpTo(RotationTargetVar1, 0, DeltaTimeX, 1);
			RotationTargetVar2 = Math::FInterpTo(RotationTargetVar2, 0, DeltaTimeX, 2);

			AccFloatVar1.SpringTo(RotationTargetVar1, 15, .2, DeltaTimeX);
			AccFloatVar2.SpringTo(RotationTargetVar2, 20, .1, DeltaTimeX);

			WheelAxisRotationVar1 = WheelAxisRotationTarget * AccFloatVar1.Value;
			WheelAxisRotationVar2 = WheelAxisRotationTarget * AccFloatVar2.Value;
		}
	}

	UFUNCTION()
	void UpdateTarget()
	{
		RotationTargetVar1 = NewRotationTarget;
		RotationTargetVar2 = NewRotationTarget;
	}

	UFUNCTION()
	private void HandleStartForward()
	{
		NewRotationTarget = 1;

		MoveWheelsDelayTimer.ClearTimer();
		MoveWheelsDelayTimer = Timer::SetTimer(this, n"UpdateTarget", START_MOVING_DELAY);
	}

	UFUNCTION()
	private void HandleStartBackward()
	{
		NewRotationTarget = -1;

		MoveWheelsDelayTimer.ClearTimer();
		MoveWheelsDelayTimer = Timer::SetTimer(this, n"UpdateTarget", START_MOVING_DELAY);
	}
}