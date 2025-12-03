class ASummitRaisableManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditInstanceOnly)
	ASummitPushablePlatform Pushable;

	UPROPERTY(EditInstanceOnly)
	ASummitRaisablePillar RaisablePillar;

	UPROPERTY(EditInstanceOnly)
	ASummitAcidActivatorOuroborosSingle AcidOuroboros;

	float RollbackDuration = 4.5;
	float RollbackCurrentTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Network::SetActorControlSide(this, Game::Mio);

		Pushable.OnSummitPushableActivated.AddUFunction(this, n"OnSummitPushableActivated");
		AcidOuroboros.OnAcidActorActivated.AddUFunction(this, n"OnAcidActorActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())
			return;

		if (RollbackCurrentTime <= 0.0)
			return;

		RollbackCurrentTime -= DeltaSeconds;
		float Alpha = Math::Clamp(RollbackCurrentTime / RollbackDuration, 0.0, 1.0);
		USummitRaisableManagerEventHandler::Trigger_OnTimerUpdate(this, FSummitRaisableManagerData(Alpha));

		if (RollbackCurrentTime <= 0.0)
		{			
			RollbackCurrentTime -= DeltaSeconds;

			if (RollbackCurrentTime <= 0.0)
			{
				CrumbResetPuzzle();
			}
		}
	}
	
	UFUNCTION()
	private void OnSummitPushableActivated()
	{
		RollbackCurrentTime = RollbackDuration;
		RaisablePillar.ActivateRaisable();
		USummitRaisableManagerEventHandler::Trigger_OnTimerStart(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbResetPuzzle()
	{
		RaisablePillar.DeactivateRaisable();
		Pushable.OnTimerCompleted();
		USummitRaisableManagerEventHandler::Trigger_OnTimerStop(this);
	}

	UFUNCTION()
	private void OnAcidActorActivated()
	{
		SetActorTickEnabled(false);
		USummitRaisableManagerEventHandler::Trigger_OnTimerStop(this);
	}

	UFUNCTION()
	void SetEndState()
	{
		SetActorTickEnabled(false);
		USummitRaisableManagerEventHandler::Trigger_OnTimerStop(this);		
	}
};