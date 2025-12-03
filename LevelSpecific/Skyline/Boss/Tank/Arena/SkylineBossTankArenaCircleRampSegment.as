class ASkylineBossTankArenaCircleRampSegment : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ScalePivot;

	UPROPERTY(DefaultComponent, Attach = ScalePivot)
	USceneComponent MeshPivot;

	UPROPERTY()
	FHazeTimeLike Animation;
	default Animation.Duration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Animation.BindUpdate(this, n"AnimationUpdate");
	
		if (AttachParentActor != nullptr)
		{
			auto CircleRamp = Cast<ASkylineBossTankArenaCircleRamp>(AttachParentActor);
			CircleRamp.OnActivateRamp.AddUFunction(this, n"HandleActivateRamp");
		}
	}

	UFUNCTION()
	private void AnimationUpdate(float CurrentValue)
	{
		float Alpha = 1.0 - CurrentValue;
		ScalePivot.RelativeScale3D = FVector(1.0, 1.0, Alpha);
	}

	UFUNCTION()
	private void HandleActivateRamp()
	{
		Activate();
	}

	void Activate()
	{
		Animation.Play();
	}
};