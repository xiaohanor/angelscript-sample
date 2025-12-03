event void FSummitTailMovablePlatformSignature();

class ASummitTailMovablePlatform : AHazeActor
{

	UPROPERTY()
	FSummitDrawBridgeSignature OnFinalMove;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRootComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent, Attach = MeshRootComp)
	USceneComponent TailActivatorForwardComp;

	UPROPERTY(DefaultComponent, Attach = MeshRootComp)
	USceneComponent TailActivatorBackwardComp;

	UPROPERTY(DefaultComponent)
	USummitMovablePlatformFloatinessComponent FloatinessComp;
	default FloatinessComp.FloatComponentName = MeshRootComp.Name;

	UPROPERTY(EditAnywhere)
	ASummitRollAttackActivator TailActivatorForward;
	UPROPERTY(EditAnywhere)
	ASummitRollAttackActivator TailActivatorBackward;

	UPROPERTY(EditAnywhere)
	ASummitRollingActivator ForwardActivator;

	UPROPERTY(EditAnywhere)
	ASummitRollingActivator BackwardActivator;

	UPROPERTY(EditAnywhere)
	bool bStartActivated = true;

	UPROPERTY(EditAnywhere)
	int NumberOfMoves = 5;
	int CurrentMove = 0;

	UPROPERTY(EditAnywhere)
	float MoveDistance = 2000;
	float MaxMoveDistance;
	
	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();
	FVector StartLocation;
	FVector EndLocation;
	FVector CurrentLocation;
    FVector MoveToLocation;

	bool bMovingForward = true;

	bool bIsDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		MaxMoveDistance = MoveDistance * NumberOfMoves;

		StartLocation = Root.GetWorldLocation();
		CurrentLocation = StartLocation;
        MoveToLocation = StartLocation + GetActorForwardVector() * MoveDistance;
		EndLocation = StartLocation + GetActorForwardVector() * (MoveDistance * NumberOfMoves);

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if(TailActivatorForward != nullptr)
		{
			TailActivatorForward.AttachToComponent(TailActivatorForwardComp);
			TailActivatorForward.OnHit.AddUFunction(this, n"HandleHitForward");
		}
		if(TailActivatorBackward != nullptr)
		{
			TailActivatorBackward.AttachToComponent(TailActivatorBackwardComp);
			TailActivatorBackward.OnHit.AddUFunction(this, n"HandleHitBackward");
		}

		if(ForwardActivator != nullptr)
		{
			ForwardActivator.AttachToComponent(TailActivatorForwardComp);
			ForwardActivator.OnActivated.AddUFunction(this, n"OnActivatedForward");
		}
		if(BackwardActivator != nullptr)
		{
			BackwardActivator.AttachToComponent(TailActivatorBackwardComp);
			BackwardActivator.OnActivated.AddUFunction(this, n"OnActivatedBackward");
		}

		if(!bStartActivated)
		{
			bIsDisabled = true;
			FloatinessComp.ToggleActive(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(TailActivatorForward != nullptr)
			TailActivatorForward.AttachToComponent(TailActivatorForwardComp);
		if(TailActivatorBackward != nullptr)
			TailActivatorBackward.AttachToComponent(TailActivatorBackwardComp);

		if(ForwardActivator != nullptr)
			ForwardActivator.AttachToComponent(TailActivatorForwardComp);
		if(BackwardActivator != nullptr)
			BackwardActivator.AttachToComponent(TailActivatorBackwardComp);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMovePlatform(bool MovingForward)
	{
		// On the remote side the animation might still be playing,
		// snap it to the end so we can play the next animation properly
		if (MoveAnimation.IsPlaying())
		{
			Root.SetWorldLocation(MoveToLocation);
			OnFinished();
			MoveAnimation.Stop();
		}

		MovePlatform(MovingForward);
	}

	UFUNCTION(BlueprintCallable)
	void MovePlatform(bool MovingForward)
	{
		if (bIsDisabled)
			return;

		if (MoveAnimation.IsPlaying())
			return;

		CurrentLocation = Root.GetWorldLocation();

		if (MovingForward) 
		{
			float Distance = (ActorLocation - StartLocation).Size();
			// Print("Distance: " + Distance, 10);
			// Print("MaxMoveDistance: " + MaxMoveDistance, 10);
			if (Distance < MaxMoveDistance - KINDA_SMALL_NUMBER)
			{
				MoveToLocation = CurrentLocation + GetActorForwardVector() * MoveDistance;
				CurrentMove++;
				if(TailActivatorForward != nullptr)
					TailActivatorForward.ActivateMove();
			}
			
		}
		else 
		{
			if (CurrentMove <= 0)
				return;
			
			float Distance = (ActorLocation - EndLocation).Size();
			// Print("Distance: " + Distance, 10);
			// Print("MaxMoveDistance: " + MaxMoveDistance, 10);

			if (Distance < MaxMoveDistance  - KINDA_SMALL_NUMBER)
			{

				MoveToLocation = CurrentLocation - GetActorForwardVector() * MoveDistance;
				CurrentMove--;
				if(TailActivatorBackward != nullptr)
					TailActivatorBackward.ActivateMove();
				
				if (CurrentMove < 0)
					CurrentMove = 0;
			}
		}

		USummitTailMovablePlatformEventHandler::Trigger_OnStartedMoving(this);

		BP_ActivateColliders();
		MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		if (bIsDisabled)
			return;

		Root.SetWorldLocation(Math::Lerp(CurrentLocation, MoveToLocation, Alpha));
	}

	
	UFUNCTION()
	void OnFinished()
	{
		// bFinishedAnimation = !MoveAnimation.IsReversed();
		BP_DeactivateColliders();

		if (CurrentMove >= NumberOfMoves)
		{
			Print("Final Move", 10);
			OnFinalMove.Broadcast();
		}

		USummitTailMovablePlatformEventHandler::Trigger_OnStoppedMoving(this);
	}

	UFUNCTION()
	void HandleHitForward()
	{
		if(bIsDisabled)
			return;
		if (MoveAnimation.IsPlaying())
			return;

		if (Game::Zoe.HasControl())
			CrumbMovePlatform(true);
	}

	UFUNCTION()
	void HandleHitBackward()
	{
		if(bIsDisabled)
			return;
		if (MoveAnimation.IsPlaying())
			return;
		
		if (Game::Zoe.HasControl())
			CrumbMovePlatform(false);
	}

	UFUNCTION()
	private void OnActivatedForward(FSummitRollingActivatorActivationParams Params)
	{
		if(bIsDisabled)
			return;
		if (MoveAnimation.IsPlaying())
			return;

		if (Game::Zoe.HasControl())
			CrumbMovePlatform(true);
	}

	UFUNCTION()
	private void OnActivatedBackward(FSummitRollingActivatorActivationParams Params)
	{
		if(bIsDisabled)
			return;
		if (MoveAnimation.IsPlaying())
			return;

		if (Game::Zoe.HasControl())
			CrumbMovePlatform(false);
	}

	UFUNCTION()
	void ResetPlatform()
	{
		if (CurrentMove <= 0)
			return;

		CurrentLocation = Root.GetWorldLocation();
		MoveToLocation = StartLocation;
		CurrentMove = 0;
		MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void DisableFurtherMovement()
	{
		if (CurrentMove >= NumberOfMoves)
			bIsDisabled = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateColliders()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateColliders()
	{
		
	}

	UFUNCTION(BlueprintCallable)
	void ToggleActive(bool bToggleOn)
	{
		if(bToggleOn)
			FloatinessComp.ToggleActive(bToggleOn);
		bIsDisabled = !bToggleOn;
	}


};