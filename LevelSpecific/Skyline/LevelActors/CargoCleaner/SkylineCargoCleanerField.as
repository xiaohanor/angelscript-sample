class ASkylineCargoCleanerField : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FieldPivot;

	UHazeSplineComponent Spline;
	FSplinePosition SplinePosition;

	FHazeAcceleratedFloat Scale;

	float ScaleTime = 2.0;
	
	bool bCanMove = true;
	bool bIsActivated = false;

	float ActivationTime = 0.0;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface Material;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic MID;

	FLinearColor Color;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TimeLike;
	default TimeLike.Curve.AddDefaultKey(0.0, 0.0);
	default TimeLike.Curve.AddDefaultKey(1.0, 1.0);
	default TimeLike.bCurveUseNormalizedTime = true;
	default TimeLike.Duration = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MID = Material::CreateDynamicMaterialInstance(this, Material);

		Color = MID.GetVectorParameterValue(n"EmissiveColor");

		TimeLike.BindUpdate(this, n"TimeLikeUpdate");
		TimeLike.BindFinished(this, n"TimeLikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		if (!bIsActivated && Time::GameTimeSeconds > ActivationTime)
//			Activate();
	
//		Scale.AccelerateTo(bIsActivated ? 0.3 : 1.0, ScaleTime, DeltaSeconds);

//		FieldPivot.RelativeLocation = FVector::RightVector * Scale.Value * -1000.0;
	}

	UFUNCTION()
	private void TimeLikeUpdate(float CurrentValue)
	{
		PrintToScreen("Hej" + CurrentValue, 0.0, FLinearColor::Green);

		MID.SetVectorParameterValue(n"EmissiveColor", Color * CurrentValue * 100.0);
	}

	UFUNCTION()
	private void TimeLikeFinished()
	{
		PrintToScreen("TimeLikeFinished", 1.0, FLinearColor::Green);

		bCanMove = true;

		if (TimeLike.IsReversed())
		{
			SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);
			SetActorLocationAndRotation(SplinePosition.WorldLocation, SplinePosition.WorldRotation);
			Activate();
		}
	}

	void Move(float Distance)
	{
		if (!bCanMove)
			return;

		bool bShouldDeactivate = !SplinePosition.Move(Distance);

		SetActorLocationAndRotation(SplinePosition.WorldLocation, SplinePosition.WorldRotation);

		if (bShouldDeactivate)
			Deactivate();
	}

	void Activate()
	{
		PrintToScreen("Activate", 1.0, FLinearColor::Green);

		bCanMove = false;
		TimeLike.Play();

		bIsActivated = true;
	}

	void Deactivate()
	{
		PrintToScreen("Deactivate", 1.0, FLinearColor::Red);

		bCanMove = false;
		TimeLike.Reverse();

		bIsActivated = false;
		ActivationTime = Time::GameTimeSeconds + ScaleTime;
		SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);
	}
};