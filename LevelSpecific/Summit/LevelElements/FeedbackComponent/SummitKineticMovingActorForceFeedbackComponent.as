class USummitKineticMovingActorForceFeedbackComponent : USummitWorldFeedbackComponent
{
	UPROPERTY(EditAnywhere)
	bool bUseOneShotOnEnd = false;

	AKineticMovingActor KineticMovingActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KineticMovingActor = Cast<AKineticMovingActor>(Owner);

		KineticMovingActor.OnStartForward.AddUFunction(this, n"StartFeedback");
		KineticMovingActor.OnStartBackward.AddUFunction(this, n"StartFeedback");
		KineticMovingActor.OnReachedForward.AddUFunction(this, n"EndFeedback");
		KineticMovingActor.OnReachedBackward.AddUFunction(this, n"EndFeedback");
	}

	UFUNCTION()
	private void StartFeedback()
	{
		StartLoopingFeedbackForBoth();
	}

	UFUNCTION()
	private void EndFeedback()
	{
		StopLoopingFeedbackForBoth();

		if (bUseOneShotOnEnd)
			PlayOneShotFeedbackForBoth();
	}
};