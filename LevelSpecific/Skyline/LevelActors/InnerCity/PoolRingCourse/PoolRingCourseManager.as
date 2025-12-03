class APoolRingCourseManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR

	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;

#endif

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	TArray<APoolRingActor> LinkedRings;

	//How long should you have inbetween rings before you fail
	UPROPERTY(EditAnywhere, Category = "Settings")
	float ActiveDuration = 3;

	private float ActiveTimer = 0;
	private float VictoryDelay = 6;
	private float VictoryTimer = 0;
	private bool bRunActive = false;
	private bool bVictoryDelayInProgress = false;

	TArray<APoolRingActor> ActiveRings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Ring : LinkedRings)
		{
			Ring.OnRingActivated.AddUFunction(this, n"OnLinkedRingActivated");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bRunActive && !bVictoryDelayInProgress)
			return;

		if(VictoryTimer > 0)
		{
			VictoryTimer -= DeltaSeconds;
			return;
		}
		else if(bVictoryDelayInProgress)
		{
			bVictoryDelayInProgress = false;
			ResetRun();
			return;
		}

		if(ActiveTimer > 0)
		{
			ActiveTimer -= DeltaSeconds;
		}
		else
		{
			ActiveTimer = 0;
			bRunActive = false;

			FPoolRingEventParams Params;
			for (auto Ring : ActiveRings)
			{
				Params.ActiveRings.Add(Ring);
				Ring.ToggleRingState(false);
			}

			UPoolRingCourseManagerEventHandler::Trigger_OnCourseFailed(this, Params);
			ActiveRings.Empty();
		}
	}

	UFUNCTION()
	private void OnLinkedRingActivated(APoolRingActor RingActor)
	{
		if(bVictoryDelayInProgress)
			return;

		if(!bRunActive)
			bRunActive = true;

		ActiveTimer = ActiveDuration;

		RingActor.ToggleRingState(true);
		ActiveRings.Add(RingActor);

		FPoolRingEventParams Params;
		Params.RingInstance = RingActor;
		UPoolRingCourseManagerEventHandler::Trigger_OnRingActivated(this, Params);

		if(ActiveRings.Num() == LinkedRings.Num())
			CompleteRun();
	}

	private void CompleteRun()
	{
		bVictoryDelayInProgress = true;
		VictoryTimer = VictoryDelay;

		FPoolRingEventParams Params;

		for (auto Ring : ActiveRings)
		{
			Params.ActiveRings.Add(Ring);
			Ring.PlayVictoryAnimation();
		}
		
		UPoolRingCourseManagerEventHandler::Trigger_OnCourseCompleted(this, Params);
	}

	private void ResetRun()
	{
		FPoolRingEventParams Params;
		
		for (auto Ring : ActiveRings)
		{
			Params.ActiveRings.Add(Ring);
			Ring.ToggleRingState(false);
		}

		UPoolRingCourseManagerEventHandler::Trigger_OnCourseReset(this, Params);

		ActiveRings.Empty();
		bRunActive = false;
		ActiveTimer = 0;
	}
};