class ASummitTopDownBrazierActivatorLid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitTopDownTailActivator Activator;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bFireEvents = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector MoveOffset = FVector(0.0, 750, 0.0);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float StartOpeningTime = 0.1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FinishOpeningTime = 0.6;
	
	UPROPERTY(EditAnywhere, Category = "Settings")
	float StartClosingTime = 0.75;
	
	UPROPERTY(EditAnywhere, Category = "Settings")
	float FinishClosingTime = 0.85;

	FVector StartLocation;
	FVector OpenLocation;

	bool bIsOpening = false;
	bool bIsClosing = false;

	bool bStartOpeningEventHasFired = false;
	bool bStartClosingEventHasFired = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		OpenLocation = MeshComp.WorldLocation + MeshComp.WorldTransform.TransformVectorNoScale(MoveOffset);
		if(Activator != nullptr)
		{
			Activator.OnHit.AddUFunction(this, n"OnActivatorHit");
			Activator.OnReset.AddUFunction(this, n"OnActivatorReset");
		}
	}

	UFUNCTION()
	private void OnActivatorHit()
	{
		bIsOpening = true;
		bStartOpeningEventHasFired = false;
		if(bFireEvents)
			USummitTopDownBrazierActivatorLidEventHandler::Trigger_OnStatueStartGoingUp(this);
	}

	UFUNCTION()
	private void OnActivatorReset()
	{
		bIsClosing = true;
		bStartClosingEventHasFired = false;
		if(bFireEvents)
			USummitTopDownBrazierActivatorLidEventHandler::Trigger_OnStatueStartGoingDown(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsOpening
		&& !bIsClosing)
			return;

		float MoveAnimAlpha = Activator.MoveAnimation.GetPosition();
		float Alpha = 0;
		FVector NewLocation = FVector::ZeroVector;
		if(bIsOpening)
		{
			Alpha = Math::GetPercentageBetween(StartOpeningTime, FinishOpeningTime, MoveAnimAlpha);
			Alpha = Math::Clamp(Alpha, 0.0, 1.0);
			
			if(!bStartOpeningEventHasFired
			&& Alpha > 0)
			{
				if(bFireEvents)
					USummitTopDownBrazierActivatorLidEventHandler::Trigger_OnLidStartOpening(this);
				bStartOpeningEventHasFired = true;
			}
			if(MoveAnimAlpha >= FinishOpeningTime)
			{
				if(bFireEvents)
					USummitTopDownBrazierActivatorLidEventHandler::Trigger_OnLidStopOpening(this);
				bIsOpening = false;
			}
			TEMPORAL_LOG(this).Status("Is Opening", FLinearColor::Green);
			NewLocation = Math::Lerp(StartLocation, OpenLocation, Alpha);
		}
		if(bIsClosing)
		{
			Alpha = Math::GetPercentageBetween(StartClosingTime, FinishClosingTime, 1 - MoveAnimAlpha);
			Alpha = Math::Clamp(Alpha, 0.0, 1.0);
			if(!bStartClosingEventHasFired
			&& Alpha > 0)
			{
				if(bFireEvents)
					USummitTopDownBrazierActivatorLidEventHandler::Trigger_OnLidStartClosing(this);
				bStartClosingEventHasFired = true;
			}
			if(1 - MoveAnimAlpha >= FinishClosingTime)
			{
				if(bFireEvents)
					USummitTopDownBrazierActivatorLidEventHandler::Trigger_OnLidStopClosing(this);
				bIsClosing = false;
			}
			TEMPORAL_LOG(this).Status("Is Closing", FLinearColor::Red);
			NewLocation = Math::Lerp(OpenLocation, StartLocation, Alpha);
		}

		MeshComp.WorldLocation = NewLocation;
		TEMPORAL_LOG(this)
			.Value("Alpha", Alpha)
			.Value("Move Anim Alpha", MoveAnimAlpha)
			.Sphere("Start Location", StartLocation, 200, FLinearColor::Black, 10)
			.Sphere("Open Location", OpenLocation, 200, FLinearColor::White, 10)
			.Sphere("Lerped Location", NewLocation, 200, FLinearColor::Purple, 10)
		;
	}	

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		auto LocalBounds = GetActorLocalBoundingBox(true);
		FVector BoundsLocation = ActorTransform.TransformPosition(LocalBounds.Center + MoveOffset);
		FVector BoundsExtent = LocalBounds.Extent * ActorScale3D;

		Debug::DrawDebugBox(BoundsLocation, BoundsExtent, ActorRotation, FLinearColor::Green, 10);
	}	
#endif
};