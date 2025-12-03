class ASolarFlareSunWaitDurationVolume : APlayerTrigger
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.92, 0.00, 1.00));
	default BrushComponent.LineThickness = 5.0;

	ASolarFlareSun Sun;

	UPROPERTY(EditAnywhere)
	bool bTriggerOnce = true;

	UPROPERTY(EditAnywhere)
	float WaitDuration = 4.0;

	bool bTriggered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		Sun = TListedActors<ASolarFlareSun>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Sun == nullptr)
			Sun = TListedActors<ASolarFlareSun>().GetSingle();
	}

    UFUNCTION()
    private void OnPlayerEnter(AHazePlayerCharacter Player)
    {
		if (bTriggerOnce && bTriggered)
			return;

		if (Sun == nullptr)
			Sun = TListedActors<ASolarFlareSun>().GetSingle();

		bTriggered = true;
		Sun.SetWaitDuration(WaitDuration);
    }
}