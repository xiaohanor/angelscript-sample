event void FSummitEggHolderListenerSignature();

class ASummitEggHolderListener : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent FirstVFXLocationComp;

	UPROPERTY(DefaultComponent)
	USceneComponent SecondVFXLocationComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ThirdVFXLocationComp;

	UPROPERTY(DefaultComponent)
	USceneComponent FourthVFXLocationComp;

	UPROPERTY(DefaultComponent)
	USceneComponent FifthVFXLocationComp;

	UPROPERTY()
	FSummitEggHolderListenerSignature OnFinished;

	UPROPERTY()
	FSummitEggHolderListenerSignature OnFailed;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitEggHolder> Children;
	bool bBeingEdited = false;

	UPROPERTY()
	bool bFinished;
	int ChildCount;
	int ChildrenActivated;

	UPROPERTY(EditInstanceOnly)
	AOneShotInteractionActor InteractionActor;

	UPROPERTY(EditInstanceOnly)
	ASummitEggHolder EggHolder1;
	UPROPERTY(EditInstanceOnly)
	ASummitEggHolder EggHolder2;
	UPROPERTY(EditInstanceOnly)
	ASummitEggHolder EggHolder3;
	UPROPERTY(EditInstanceOnly)
	ASummitEggHolder EggHolder4;

	UPROPERTY(EditInstanceOnly)
	AActorTrigger Trigger1;
	UPROPERTY(EditInstanceOnly)
	AActorTrigger Trigger2;
	UPROPERTY(EditInstanceOnly)
	AActorTrigger Trigger3;

	UPROPERTY(EditInstanceOnly)
	ASummitEggMagicalBeam EggBeam1;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor MovingActor1;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor MovingActor2;

	UPROPERTY(EditInstanceOnly)
	AKineticMovingActor MovingActor3;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect SuccessForceFeedback;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger1.OnActorBeginOverlap.AddUFunction(this, n"HandleTriggerOne");
		Trigger2.OnActorBeginOverlap.AddUFunction(this, n"HandleTriggerTwo");
		Trigger3.OnActorBeginOverlap.AddUFunction(this, n"HandleTriggerThree");
	}

	UFUNCTION()
	void HandleTriggerOne(AActor OverlappedActor, AActor OtherActor)
	{
		if (OtherActor != EggBeam1)
			return;

		// validate from control side to prevent desync issues
		if (!HasControl())
			return;

		// if eggholder one is placed trigger next spline actor else spawn vfx and POI and reset puzzle.
		if (EggHolder1.bEggIsPlaced)
		{
			CrumbSuccessEggPlacement(1);
			return;
		}
		else
		{
			CrumbFailedEggPlacement(1);
		}
	}

	UFUNCTION()
	void HandleTriggerTwo(AActor OverlappedActor, AActor OtherActor)
	{
		if (OtherActor != EggBeam1)
			return;

		// validate from control side to prevent desync issues
		if (!HasControl())
			return;

		// if eggholder one is placed trigger next spline actor else spawn vfx and POI and reset puzzle.
		if (EggHolder2.bEggIsPlaced)
		{
			CrumbSuccessEggPlacement(2);
			return;
		}
		else
		{
			CrumbFailedEggPlacement(2);
		}
	}

	UFUNCTION()
	void HandleTriggerThree(AActor OverlappedActor, AActor OtherActor)
	{
		if (OtherActor != EggBeam1)
			return;

		// validate from control side to prevent desync issues
		if (!HasControl())
			return;

		// if eggholder one is placed trigger next spline actor else spawn vfx and POI and reset puzzle.
		if (EggHolder3.bEggIsPlaced && EggHolder4.bEggIsPlaced)
		{
			CrumbCompletePuzzle();
		}
		else
		{
			if (EggHolder3.bEggIsPlaced)
				CrumbFailedEggPlacement(4);
			else
				CrumbFailedEggPlacement(3);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbCompletePuzzle()
	{
		check(MovingActor3 != nullptr, "EggHolderListener: MovingActor3 was null!");
		MovingActor3.ActivateForward();
		EggHolder3.BP_DisableEggHolder();
		EggHolder3.PickUpEggForCurrentPlayer();
		EggHolder4.BP_DisableEggHolder();
		EggHolder4.PickUpEggForCurrentPlayer();
		if (SuccessForceFeedback != nullptr)
		{
			if (EggHolder3.CurrentPlayer != nullptr)
				EggHolder3.CurrentPlayer.PlayForceFeedback(SuccessForceFeedback, false, false, this);
			if (EggHolder4.CurrentPlayer != nullptr)
				EggHolder4.CurrentPlayer.PlayForceFeedback(SuccessForceFeedback, false, false, this);
		}
		EggPuzzleComplete();
	}

	UFUNCTION()
	void EggPuzzleComplete()
	{
		EggBeam1.DeactivateEggBeam();
		BP_FailedEggPlacement(5);
		BP_PuzzleComplete();
		OnFinished.Broadcast();
	}

	UFUNCTION(CrumbFunction)
	void CrumbFailedEggPlacement(int EggHolderNumber)
	{
		EggBeam1.DeactivateEggBeam();
		BP_FailedEggPlacement(EggHolderNumber);
		OnFailed.Broadcast();

		if (MovingActor1 != nullptr)
			MovingActor1.ReverseBackwards();
		if (MovingActor2 != nullptr)
			MovingActor2.ReverseBackwards();
		if (MovingActor3 != nullptr)
			MovingActor3.ReverseBackwards();

		EggHolder1.BP_EnableEggHolder();
		EggHolder2.BP_EnableEggHolder();
		EggHolder3.BP_EnableEggHolder();
		EggHolder4.BP_EnableEggHolder();
	}

	UFUNCTION(CrumbFunction)
	void CrumbSuccessEggPlacement(int EggHolderNumber)
	{
		if (EggHolderNumber == 1)
		{
			check(MovingActor1 != nullptr, "EggHolderListener: MovingActor1 was null!");
			MovingActor1.ActivateForward();
			EggHolder1.PickUpEggForCurrentPlayer();
			EggHolder1.BP_DisableEggHolder();

			if (SuccessForceFeedback != nullptr)
			{
				if (EggHolder1.CurrentPlayer != nullptr)
					EggHolder1.CurrentPlayer.PlayForceFeedback(SuccessForceFeedback, false, false, this);
			}
			return;
		}
		if (EggHolderNumber == 2)
		{
			check(MovingActor2 != nullptr, "EggHolderListener: MovingActor1 was null!");
			MovingActor2.ActivateForward();
			EggHolder2.PickUpEggForCurrentPlayer();
			EggHolder2.BP_DisableEggHolder();
			if (SuccessForceFeedback != nullptr)
			{
				if (EggHolder2.CurrentPlayer != nullptr)
					EggHolder2.CurrentPlayer.PlayForceFeedback(SuccessForceFeedback, false, false, this);
			}
			return;
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_PuzzleComplete()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_FailedEggPlacement(int EggHolderNumber)
	{
	}
}