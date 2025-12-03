event void FSkylineMoverSignature();

class ASkylineMover : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FTransform TargetTransform;

	FTransform InitialTransform;

	UPROPERTY(EditAnywhere)
	FName MovingComponentName;

	USceneComponent MovingComponent;

	UPROPERTY(EditAnywhere)
	AActor TriggeringActor;

	UPROPERTY(EditAnywhere)
	TArray<ASkylineMover> MoversToTrigger;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Animation;
	default Animation.Duration = 1.0;
	default Animation.bCurveUseNormalizedTime = true;
	default Animation.Curve.AddDefaultKey(0.0, 0.0);
	default Animation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	bool bDeactivateOnTriggerLeave = false;

	UPROPERTY(EditAnywhere)
	bool bAutoDeactivate = false;

	UPROPERTY(EditAnywhere)
	float DelayBeforeActivation = 0.0;

	UPROPERTY(EditAnywhere)
	float DelayBeforeDeactivation = 0.0;

	FTimerHandle DeactivationTimer;
	bool bIsActivated = false;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedback;

	UInteractionComponent InteractionComponent;

	UPROPERTY()
	FSkylineMoverSignature OnMoverActivated;

	UPROPERTY()
	FSkylineMoverSignature OnMoverFinished;

	UPROPERTY(EditInstanceOnly)
	FHazeAudioZoneRelevanceController ZoneRelevanceController;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovingComponent = USceneComponent::Get(this, MovingComponentName);

		if (MovingComponent == nullptr)
			MovingComponent = Root;

		InitialTransform = MovingComponent.RelativeTransform;

		Animation.BindUpdate(this, n"OnUpdate");
		Animation.BindFinished(this, n"OnFinished");

		if (TriggeringActor == nullptr)
			TriggeringActor = this;

		if (TriggeringActor != nullptr)
		{
			auto PlayerTrigger = Cast<APlayerTrigger>(TriggeringActor);
			if (PlayerTrigger != nullptr)
			{
				PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerTriggerEnter");
				PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerTriggerLeave");
			}

			auto Fuse = Cast<ASkylineFuse>(TriggeringActor);
			if (Fuse != nullptr)
			{
				Fuse.OnFuseDisabled.AddUFunction(this, n"OnFuseDisabled");
				Fuse.OnFuseEnabled.AddUFunction(this, n"OnFuseEnabled");
			}

			InteractionComponent = UInteractionComponent::Get(TriggeringActor);
			if (InteractionComponent != nullptr)
			{
				InteractionComponent.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
				if (InteractionComponent.Class == UThreeShotInteractionComponent)
				{
					InteractionComponent.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
					bAutoDeactivate = false;
				}
			}

			auto GravityBladeResponseComponent = UGravityBladeCombatResponseComponent::Get(TriggeringActor);
			if (GravityBladeResponseComponent != nullptr)
			{
				GravityBladeResponseComponent.OnHit.AddUFunction(this, n"OnBladeHitActivation");
			}

			auto SkylineInterfaceComponent = USkylineInterfaceComponent::Get(TriggeringActor);
			if (SkylineInterfaceComponent != nullptr)
			{
				SkylineInterfaceComponent.OnActivated.AddUFunction(this, n"OnInterfaceActivated");
				SkylineInterfaceComponent.OnDeactivated.AddUFunction(this, n"OnInterfaceDeactivated");
			}
		}

		// This will only be used on those with valid references.
		if (!ZoneRelevanceController.Zone.IsNull())
		{
			ZoneRelevanceController.Initialize();
			ZoneRelevanceController.SetRelevanceMultiplier(1.0, this);
		}
	}

	UFUNCTION()
	private void OnInterfaceActivated(AActor Caller)
	{
		Activate();
	}

	UFUNCTION()
	private void OnInterfaceDeactivated(AActor Caller)
	{
		Deactivate();
	}

	UFUNCTION()
	private void OnFuseDisabled()
	{
		Activate();
	}

	UFUNCTION()
	private void OnFuseEnabled()
	{
		Deactivate();
	}

	UFUNCTION()
	private void OnBladeHitActivation(UGravityBladeCombatUserComponent UserComp, FGravityBladeHitData HitData)
	{
		Activate();
	}

	UFUNCTION()
	private void OnPlayerTriggerEnter(AHazePlayerCharacter Player)
	{
		Activate();
	}

	UFUNCTION()
	private void OnPlayerTriggerLeave(AHazePlayerCharacter Player)
	{
		if (bDeactivateOnTriggerLeave)
			Deactivate();
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
	//	PrintScaled("Interact", 1.0, FLinearColor::Green, 4.0);
		if (!bIsActivated)
			Activate();
		else
			Deactivate();
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
	//	PrintScaled("InteractionStopped", 1.0, FLinearColor::Green, 4.0);
		Deactivate();
	}

	UFUNCTION()
	void Activate()
	{
		bIsActivated = true;

		if (DelayBeforeActivation > 0.0)
			Timer::SetTimer(this, n"DelayedActivate", DelayBeforeActivation);
		else
			DelayedActivate();
	}

	UFUNCTION()
	void DelayedActivate()
	{
		OnMoverActivated.Broadcast();

		bIsActivated = true;

		DeactivationTimer.ClearTimer();
//		Animation.PlayWithAcceleration(1.0);

		Animation.Play();

		if (InteractionComponent != nullptr && InteractionComponent.Class != UThreeShotInteractionComponent)
			InteractionComponent.Disable(this);

		if (ForceFeedback != nullptr)
			for (auto Player : Game::Players)
				Player.PlayForceFeedback(ForceFeedback, true, true, this, 1.0);

//			ForceFeedback::Pla(ForceFeedback, ActorLocation, true, this, 1000.0, 2000.0);
	}

	UFUNCTION()
	void Stop()
	{
		Animation.Stop();

		for (auto Player : Game::Players)
			Player.StopForceFeedback(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		bIsActivated = false;

		DeactivationTimer.ClearTimer();
//		Animation.StopWithDeceleration(1.0);
		Animation.Reverse();

		if (InteractionComponent != nullptr && InteractionComponent.Class != UThreeShotInteractionComponent)
			InteractionComponent.Disable(this);
	}

	void TriggerMovers()
	{
		for (auto Mover : MoversToTrigger)
			Mover.Activate();
	}

	UFUNCTION()
	private void OnUpdate(float Alpha)
	{
		FTransform Transform;
		Transform.Location = Math::Lerp(InitialTransform.Location, (TargetTransform * InitialTransform).Location, Alpha);
		Transform.Rotation = FQuat::Slerp(InitialTransform.Rotation, (TargetTransform * InitialTransform).Rotation, Alpha);

		MovingComponent.RelativeTransform = Transform;

		if(ZoneRelevanceController.Zone.IsValid())
			ZoneRelevanceController.SetRelevanceMultiplier(Alpha, this);
	}

	UFUNCTION()
	private void OnFinished()
	{
		if (!Animation.IsReversed())
		{
			OnMoverFinished.Broadcast();
			TriggerMovers();

			if (!bAutoDeactivate && InteractionComponent != nullptr)
				InteractionComponent.Enable(this);
		}
		else if (InteractionComponent != nullptr)
			InteractionComponent.Enable(this);

		if (bAutoDeactivate)
			DeactivationTimer = Timer::SetTimer(this, n"OnDeactivationTimer", DelayBeforeDeactivation);

		for (auto Player : Game::Players)
			Player.StopForceFeedback(this);
	}

	UFUNCTION()
	private void OnDeactivationTimer()
	{
		Deactivate();
	}

	UFUNCTION()
	void SnapToEnd()
	{
		Animation.SetNewTime(Animation.Duration);
		OnUpdate(Animation.Value);
	}

	UFUNCTION()
	void InitializeClosed()
	{
		// Audio
		if (!ZoneRelevanceController.Zone.IsNull())
		{
			ZoneRelevanceController.SetRelevanceMultiplier(0.0, this);
		}
	}
}