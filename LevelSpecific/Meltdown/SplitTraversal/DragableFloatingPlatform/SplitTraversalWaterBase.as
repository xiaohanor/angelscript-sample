event void FSplitTraversalOnAttachedToConveyor();

class ASplitTraversalWaterBase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WaterLevelRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent BoundarySplineComp;

	UPROPERTY(DefaultComponent, Attach = WaterLevelRoot)
	UFauxPhysicsTranslateComponent SplineTranslateComp;

	UPROPERTY(DefaultComponent, Attach = WaterLevelRoot)
	UArrowComponent PushRoot;

	UPROPERTY(EditAnywhere)
	float TargetHeight = 1000.0;

	UPROPERTY(EditAnywhere)
	float CurrentRadius = 1000.0;

	UPROPERTY(EditAnywhere)
	float CurrentStrength = 1500.0;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalBranchLever RaiseWaterLever;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalCatWaterfall CatHead;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike RaiseWaterTimeLike;
	default RaiseWaterTimeLike.UseSmoothCurveZeroToOne();
	default RaiseWaterTimeLike.Duration = 5.0;

	UPROPERTY()
	FSplitTraversalOnAttachedToConveyor OnAttachedToConveyor;

	FBranchLeverActivated OnRaiseWaterLeverActivated;
	FBranchLeverActivated OnSwitchCurrentLeverActivated;

	bool bCurrentActivated = false;
	bool bCurrentReversed = false;
	bool bAttachedToConveyor = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RaiseWaterTimeLike.BindUpdate(this, n"RaiseWaterTimeLikeUpdate");
		RaiseWaterTimeLike.BindFinished(this, n"RaiseWaterTimeLikeFinished");
		RaiseWaterLever.OnReachedEnd.AddUFunction(this, n"RaiseWaterLevel");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (RaiseWaterTimeLike.IsPlaying() && CatHead.WaterLocation.Z < 200.0)
		{
			FVector ForceDirection = PushRoot.ForwardVector;
			float ForceMultiplier = Math::Lerp(1.0, 0.0, 
									Math::Min(SplineTranslateComp.WorldLocation.Distance(PushRoot.WorldLocation) / CurrentRadius, 1.0));

			SplineTranslateComp.ApplyForce(PushRoot.WorldLocation, ForceDirection * ForceMultiplier * CurrentStrength);
		}
	}

	UFUNCTION()
	void RaiseWaterLevel()
	{
		RaiseWaterTimeLike.Play();
		OnRaiseWaterLeverActivated.Broadcast();
		CatHead.Activate();
	}

	UFUNCTION()
	private void RaiseWaterTimeLikeUpdate(float CurrentValue)
	{
		WaterLevelRoot.SetRelativeLocation(FVector::UpVector * TargetHeight * CurrentValue);
		CatHead.WaterLocation = FVector::UpVector * Math::Lerp(-950.0, 500, CurrentValue);
	}

	UFUNCTION()
	private void RaiseWaterTimeLikeFinished()
	{
	}
};