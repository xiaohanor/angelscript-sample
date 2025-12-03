class ASkylineBossArenaCenterHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftHatchDoorPivot;

	UPROPERTY(DefaultComponent)
	USceneComponent RightHatchDoorPivot;

	UPROPERTY(DefaultComponent)
	USceneComponent CenterLiftPivot;

	UPROPERTY(EditAnywhere)
	float HatchDoorDistance = 5000.0;

	UPROPERTY(EditAnywhere)
	float CenterLiftDistance = 5000.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike HatchDoorAnimation;
	default HatchDoorAnimation.Duration = 2.0;
	default HatchDoorAnimation.bCurveUseNormalizedTime = true;
	default HatchDoorAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default HatchDoorAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FHazeTimeLike CenterLiftAnimation;
	default CenterLiftAnimation.Duration = 3.0;
	default CenterLiftAnimation.bCurveUseNormalizedTime = true;
	default CenterLiftAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default CenterLiftAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditInstanceOnly)
	AActor AttachToLiftPivot;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams IntroSlotAnim;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams TransformSlotAnim;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CenterLiftPivot.RelativeLocation = -FVector::UpVector * CenterLiftDistance;

		if (AttachToLiftPivot != nullptr)
		{
			AttachToLiftPivot.AttachToComponent(CenterLiftPivot);
			AttachToLiftPivot.AddActorDisable(this);
		}

		HatchDoorAnimation.BindUpdate(this, n"HandleHatchDoorAnimationUpdate");
		HatchDoorAnimation.BindFinished(this, n"HandleHatchDoorAnimationFinished");
		CenterLiftAnimation.BindUpdate(this, n"HandleCenterLiftAnimationUpdate");
		CenterLiftAnimation.BindFinished(this, n"HandleCenterLiftAnimationFinished");
	}

	UFUNCTION(BlueprintCallable)
	void SnapIntroAnimationToEnd()
	{
		PlaySlotAnimation(IntroSlotAnim);
		SetSlotAnimationPosition(IntroSlotAnim.Animation, IntroSlotAnim.PlayLength);
	}

	UFUNCTION(BlueprintCallable)
	void SnapTransformAnimationToEnd()
	{
		PlaySlotAnimation(TransformSlotAnim);
		SetSlotAnimationPosition(TransformSlotAnim.Animation, TransformSlotAnim.PlayLength);
	}

	UFUNCTION()
	void OpenHatchDoor()
	{
		HatchDoorAnimation.Play();
		AttachToLiftPivot.RemoveActorDisable(this);
	}

	UFUNCTION()
	private void HandleHatchDoorAnimationUpdate(float CurrentValue)
	{
		LeftHatchDoorPivot.RelativeLocation = FVector::RightVector * HatchDoorDistance * CurrentValue;
		RightHatchDoorPivot.RelativeLocation = -FVector::RightVector * HatchDoorDistance * CurrentValue;
	}

	UFUNCTION()
	private void HandleHatchDoorAnimationFinished()
	{
		if (HatchDoorAnimation.IsReversed())
			AttachToLiftPivot.DetachFromActor();
		else
			CenterLiftAnimation.Play();
	}

	UFUNCTION()
	private void HandleCenterLiftAnimationUpdate(float CurrentValue)
	{
		CenterLiftPivot.RelativeLocation = -FVector::UpVector * CenterLiftDistance * (1.0 - CurrentValue);
	}

	UFUNCTION()
	private void HandleCenterLiftAnimationFinished()
	{
		HatchDoorAnimation.Reverse();
	}

	UFUNCTION()
	void SnapToEnd()
	{
		HatchDoorAnimation.SetNewTime(HatchDoorAnimation.Duration);
		CenterLiftAnimation.SetNewTime(CenterLiftAnimation.Duration);
		LeftHatchDoorPivot.RelativeLocation = FVector::RightVector * HatchDoorDistance * 0.0;
		RightHatchDoorPivot.RelativeLocation = -FVector::RightVector * HatchDoorDistance * 0.0;
		CenterLiftPivot.RelativeLocation = -FVector::UpVector * CenterLiftDistance * (1.0 - 1.0);

		if (AttachToLiftPivot != nullptr)
		{
			AttachToLiftPivot.RemoveActorDisable(this);
			AttachToLiftPivot.DetachFromActor();
		}
	}
};