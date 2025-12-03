event void ESummitCatapultLauncherStatueEvent();

class ASummitCatapultLauncherStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent HandRotateRoot;

	UPROPERTY(DefaultComponent, Attach = HandRotateRoot)
	USceneComponent HandImpulseRotateRoot;

	UPROPERTY(DefaultComponent, Attach = HandRotateRoot)
	USceneComponent HandImpactLocation;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 75000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float HandUpRotateMax = 90.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GoUpForce = 100.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float GoDownForce = 50.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PercentageHandsCountAsDown = 0.05;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PercentageHandsCountAsGrabbing = 0.1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartUp = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	ASummitAcidActivatorActor Activator;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRotation;

	ESummitCatapultLauncherStatueEvent OnReachedGrabbingLevel;
	ESummitCatapultLauncherStatueEvent OnLeftGrabbingLevel;

	float LastTimeAcidHit;

	bool bIsUp = false;
	bool bHasFiredGrabbingLevelEvent = false;

	FHazeAcceleratedRotator AccImpulseRotation;

	const float ImpactImpulseSize = 50.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		if(Activator != nullptr)
			Activator.OnAcidActorActivated.AddUFunction(this, n"OnAcidActorActivated");

		bIsUp = bStartUp;
	}

	UFUNCTION()
	private void OnMinConstraintHit(float Strength)
	{
		if(bHasFiredGrabbingLevelEvent)
			return;

		if(bIsUp)
			return;

		OnReachedGrabbingLevel.Broadcast();
		bHasFiredGrabbingLevelEvent = true;
	}

	UFUNCTION()
	private void OnAcidActorActivated()
	{
		if(!bIsUp && HandsCountAsGrabbing())
			OnLeftGrabbingLevel.Broadcast();	

		bHasFiredGrabbingLevelEvent = false;

		if(bIsUp)
			USummitCatapultLauncherStatueEventHandler::Trigger_OnHandsLowered(this);
		else
			USummitCatapultLauncherStatueEventHandler::Trigger_OnHandsRaised(this);

		bIsUp = !bIsUp;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bStartUp)
			HandRotateRoot.RelativeRotation = FRotator(0.0, 0.0, -HandUpRotateMax);
		else
			HandRotateRoot.RelativeRotation = FRotator(0.0, 0.0, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			auto Ouroboros = Cast<ASummitAcidActivatorOuroborosSingle>(Activator);
			if(Ouroboros == nullptr)
				return;

			float ActivatorAlpha = Ouroboros.GetRotateAlpha();

			FRotator StartRotation;
			FRotator TargetRotation;

			if(bIsUp)
			{
				StartRotation = FRotator(0.0, 0.0, -HandUpRotateMax);
				TargetRotation = FRotator::ZeroRotator;
			}
			else
			{
				StartRotation = FRotator::ZeroRotator;
				TargetRotation = FRotator(0.0, 0.0, -HandUpRotateMax);
				if(!bHasFiredGrabbingLevelEvent
				&& HandsCountAsGrabbing())
				{
					bHasFiredGrabbingLevelEvent = true;
					CrumbBroadcastGrabbingLevel();
				}
			}

			FRotator LerpedRotation = Math::LerpShortestPath(StartRotation, TargetRotation, ActivatorAlpha);

			TEMPORAL_LOG(this)
				.Value("Lerped Rotation", LerpedRotation)
			;

			HandRotateRoot.RelativeRotation = LerpedRotation;
			SyncedRotation.SetValue(LerpedRotation);
		}
		else
		{
			HandRotateRoot.RelativeRotation = SyncedRotation.Value;
		}

		AccImpulseRotation.ThrustTo(FRotator::ZeroRotator, 150.0, DeltaSeconds);
		HandImpulseRotateRoot.RelativeRotation = AccImpulseRotation.Value;
	}

	UFUNCTION(CrumbFunction)
	void CrumbBroadcastGrabbingLevel()
	{
		OnReachedGrabbingLevel.Broadcast();
	}

	bool HandsAreDown() const
	{
		float Alpha = GetRotateAlpha();
		return Math::IsNearlyZero(Alpha, PercentageHandsCountAsDown);
	}

	bool HandsCountAsGrabbing() const
	{
		float Alpha = GetRotateAlpha();
		return Math::IsNearlyZero(Alpha, PercentageHandsCountAsGrabbing);
	}

	float GetRotateAlpha() const
	{
		auto Ouroboros = Cast<ASummitAcidActivatorOuroborosSingle>(Activator);
		if(Ouroboros == nullptr)
			return 0;

		return Ouroboros.GetRotateAlpha();
	}

	void ApplyRotateImpulse(bool bImpactedFromFront)
	{
		float Impulse = ImpactImpulseSize;
		if(!bImpactedFromFront)
			Impulse *= -1;

		AccImpulseRotation.Velocity += FRotator(0.0, 0.0, Impulse);

		FSummitCatapultLauncherStatueOnImpactedByCartParams Params;
		Params.ImpactLocation = HandImpactLocation.WorldLocation;
		USummitCatapultLauncherStatueEventHandler::Trigger_OnHandsImpactedByCart(this, Params);
	}
};