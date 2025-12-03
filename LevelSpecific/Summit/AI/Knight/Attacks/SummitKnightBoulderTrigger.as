class ASummitKnightBoulderTrigger : APlayerTrigger
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.67, 0.71, 0.35));
	default bTriggerForZoe = true;
	default bTriggerForMio = false;
	
	UPROPERTY(EditInstanceOnly)
	ASummitKnightBoulder Boulder;

	UPROPERTY(EditAnywhere, Meta = (InlineEditConditionToggle))
	bool bRepeatLaunch = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bRepeatLaunch", InlineEditCondition))
	float RepeatLaunchInterval = 7.0;

	bool bHasLaunchedBoulder = false;
	float NextLaunchTime = 0.0;

#if EDITOR
	UPROPERTY(DefaultComponent)	
	UDummyVisualizationComponent VisComp;
	default VisComp.Thickness = 20.0;
	default VisComp.DashSize = 100.0;
	default VisComp.Color = FLinearColor::Red;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		VisComp.ConnectedActors.Empty();
		if (Boulder != nullptr)
			VisComp.ConnectedActors.Add(Boulder);
	}
#endif	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnEnter");
		OnPlayerLeave.AddUFunction(this, n"OnLeave");
	}

	UFUNCTION()
	private void OnEnter(AHazePlayerCharacter Player)
	{
		if (bHasLaunchedBoulder && !bRepeatLaunch)
			return;

		SetActorTickEnabled(true);
		float CurTime = Time::GameTimeSeconds;

		// If this is first launch or we've passed next launch time, restart launch intervals
		if (NextLaunchTime < CurTime)
			NextLaunchTime = CurTime; 		
	}

	UFUNCTION()
	private void OnLeave(AHazePlayerCharacter Player)
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!IsValid(Boulder))
			return;
		if (bHasLaunchedBoulder && !bRepeatLaunch)
		{
			// Something else started us ticking
			SetActorTickEnabled(false);
			return;
		}

		if ((Time::GameTimeSeconds > NextLaunchTime) && !Boulder.bIsMoving)
		{
			bHasLaunchedBoulder = true;
			NextLaunchTime = Time::GameTimeSeconds + RepeatLaunchInterval;
			if (!bRepeatLaunch)
				SetActorTickEnabled(false);
			Boulder.Launch();
		}
	}
};