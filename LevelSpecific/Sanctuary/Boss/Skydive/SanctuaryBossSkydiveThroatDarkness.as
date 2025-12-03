class ASanctuaryBossSkydiveThroatDarkness : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSphereComponent HazeSphere;

	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueComp;
	UPROPERTY()
	FRuntimeFloatCurve FloatCurve;

	float StartingOpacity;
	float TargetOpacity = 0.0;

	bool bDoOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnPlayerEnter.AddUFunction(this, n"HandleOnPlayerEnter");
		StartingOpacity =  HazeSphere.Opacity;
	}

	UFUNCTION()
	private void HandleOnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(bDoOnce)
			HazeSphereAppear();
	}

	UFUNCTION(BlueprintCallable)
	void HazeSphereAppear()
	{
		bDoOnce = false;
		ActionQueComp.Duration(1.0, this, n"HandleHazeSphereAppear");
	}

	UFUNCTION()
	private void HandleHazeSphereAppear(float Alpha)
	{
		float AlphaValue = FloatCurve.GetFloatValue(Alpha);
		HazeSphere.SetOpacityValue((Math::Lerp(StartingOpacity, TargetOpacity, AlphaValue)));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreen("OPACITY: " + HazeSphere.Opacity);
	}
};