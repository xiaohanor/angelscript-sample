class AIslandGrindObstacleDisplayCounter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTextRenderComponent CountDownText;
	
	UPROPERTY(DefaultComponent)
	UTextRenderComponent InActiveText;
		
	UPROPERTY(DefaultComponent)
	UTextRenderComponent ActiveText;

	UPROPERTY(EditAnywhere)
	AIslandGrindObstacleListener ListenerRef;

	UPROPERTY(EditAnywhere)
	bool bDelayUpdate;

	FHazeTimeLike DelayAnimation;	
	default DelayAnimation.Duration = 1.9;
	default DelayAnimation.UseLinearCurveZeroToOne();

	float CurrentPercentage;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ListenerRef.OnUpdateDisplay.AddUFunction(this, n"OnUpdateDisplay");
		DelayAnimation.BindFinished(this, n"OnFinished");
	}

	UFUNCTION()
	private void OnUpdateDisplay(float PercentageAlpha)
	{
		if (bDelayUpdate)
		{
			DelayAnimation.PlayFromStart();
			CurrentPercentage = PercentageAlpha;
			return;
		}

		int Percentage = Math::FloorToInt(PercentageAlpha * 100.0);
		CountDownText.SetText(FText::FromString(f"{Percentage}%"));
	}

	UFUNCTION()
	void OnFinished()
	{
		int Percentage = Math::FloorToInt(CurrentPercentage * 100.0);
		CountDownText.SetText(FText::FromString(f"{Percentage}%"));
	}
}