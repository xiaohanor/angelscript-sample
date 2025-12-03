event void ESummitAirCurrentEvent();

class ASummitAirCurrent : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent WindCurrentSystem;
	default WindCurrentSystem.SetRelativeLocation(FVector(0.0, 0.0, -500.0));

	UPROPERTY(DefaultComponent)
	UBoxComponent CurrentBox;
	default CurrentBox.BoxExtent = FVector(500.0, 500.0, 500.0);
#if EDITOR
	default CurrentBox.LineThickness = 5.0;
	default CurrentBox.ShapeColor = FColor::Green;
#endif

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;

	UPROPERTY(DefaultComponent)
	UArrowComponent UpArrow;
	default UpArrow.RelativeRotation = FRotator(90.0, 0.0, 0.0);
	default UpArrow.ArrowSize = 5.0;
	default UpArrow.ArrowColor = FLinearColor::Green;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditAnywhere)
	float SpeedOfCurrent = 1700.0;

	UPROPERTY(EditAnywhere)
	float AccelerationOfCurrent = 2200.0;

	UPROPERTY(EditAnywhere)
	bool bShouldBeBlocked = false;

	UPROPERTY(EditAnywhere)
	bool bAutoActivateGlide = false;

	UPROPERTY(EditAnywhere)
	bool bStartDisabled = false;
	
	//Max distance before rumble intensity reaches 0
	//-1 value for always play rumble
	UPROPERTY(EditAnywhere)
	float ForceFeedbackMaxDistance = 2000.0;

	//Curve over alpha for how intense rumble will be
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve RuntimeCurve;
	default RuntimeCurve.AddDefaultKey(0.0, 1.0);
	default RuntimeCurve.AddDefaultKey(0.5, 0.7);
	default RuntimeCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY()
	UForceFeedbackEffect Rumble;

	ESummitAirCurrentEvent OnDragonStartedAscending;

	TArray<FInstigator> Disablers;

	const FName StartDisabled = n"StartDisabled"; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bStartDisabled)
		{
			AddDisabler(StartDisabled);
			Deactivate();
		}
		else
		{
			Activate();
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bStartDisabled)
			WindCurrentSystem.bAutoActivate = false;
		else
			WindCurrentSystem.bAutoActivate = true;
	}

	void Activate()
	{
		WindCurrentSystem.Activate();
		USummitAirCurrentEventHandler::Trigger_OnStartedBlowing(this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			float Distance = (Player.ActorLocation - ActorLocation).Size();
			float Alpha = Distance / ForceFeedbackMaxDistance;
			Alpha = 1 - Alpha;
			float Multiplier = RuntimeCurve.GetFloatValue(Math::Saturate(Alpha));

			if (ForceFeedbackMaxDistance < 0.0)
				Multiplier = 1.0;

			if (Distance < ForceFeedbackMaxDistance)
				Player.PlayForceFeedback(Rumble, false, true, this, Multiplier);
		}
	}

	void Deactivate()
	{
		WindCurrentSystem.Deactivate();
		USummitAirCurrentEventHandler::Trigger_OnStoppedBlowing(this);
	}

	void AddDisabler(FInstigator Disabler) 
	{
		if(IsEnabled())
			Deactivate();

		Disablers.AddUnique(Disabler);
	}

	void RemoveDisabler(FInstigator Disabler) 
	{
		// if (!devEnsure(Disablers.Contains(Disabler), "" + Name + " was not previously disabled by " + Disabler + ". no disabler found to remove"))
		// 	return;

		Disablers.Remove(Disabler);

		if(IsEnabled())
			Activate();
	}

	bool IsEnabled() const
	{
		return Disablers.Num() == 0;
	}

	UFUNCTION()
	bool AirCurrentIsBlocked()
	{
		if(!bShouldBeBlocked)
			return false;

		FHazeTraceSettings Trace;
		Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();

		auto HitResults = Trace.QueryTraceSingle(ActorLocation, 
		ActorLocation + ActorUpVector * CurrentBox.BoxExtent.Z);

		if(HitResults.bBlockingHit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintCallable)
	void RemoveStartDisabler()
	{
		if(!bStartDisabled)
			return;

		if(!Disablers.Contains(StartDisabled))
			return;

		RemoveDisabler(StartDisabled);
	}
};