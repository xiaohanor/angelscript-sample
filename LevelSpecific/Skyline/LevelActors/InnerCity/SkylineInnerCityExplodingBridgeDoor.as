class ASkylineInnerCityExplodingBridgeDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent,)
	USceneComponent DoorPivot;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Animation;
	default Animation.Duration = 1.0;
	default Animation.bCurveUseNormalizedTime = true;
	default Animation.Curve.AddDefaultKey(0.0, 0.0);
	default Animation.Curve.AddDefaultKey(1.0, 1.0);

	bool bActivated = false;

	float DoorDistance = 700.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");

		Animation.BindUpdate(this, n"OnAnimationUpdate");
		Animation.BindFinished(this, n"OnAnimationFinished");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		Activate();
	}

	UFUNCTION()
	void OnAnimationUpdate(float Value)
	{
		DoorPivot.RelativeLocation = -FVector::UpVector * DoorDistance * Value; 
	}

	UFUNCTION()
	void OnAnimationFinished()
	{
	}

	UFUNCTION()
	void Activate()
	{
		if (bActivated)
			return;

		Animation.Play();

		bActivated = true;
	}
};