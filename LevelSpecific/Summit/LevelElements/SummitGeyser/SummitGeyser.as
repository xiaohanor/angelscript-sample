event void USummitGeyserEvent();

class ASummitGeyser : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	UPROPERTY(DefaultComponent)
	UCapsuleComponent LaunchTrigger;
	default LaunchTrigger.SetCollisionProfileName(n"TriggerOnlyPlayer");

	UPROPERTY(DefaultComponent)
	UNiagaraComponent GeyserEffect;
	default GeyserEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilityClasses.Add(USummitGeyserLaunchCapability);
	// default RequestComp.PlayerCapabilityClasses.Add(USummitGeyserBuildUpFeedbackCapability);

	// How long an eruption should last visually
	UPROPERTY(EditAnywhere, Category = "Summit Geyser")
	float EruptionDuration = 0.5;

	UPROPERTY(EditAnywhere, Category = "Summit Geyser")
	float EruptionLaunchDelay = 0.3;

	// The point that the player should reach when launching
	UPROPERTY(EditAnywhere, Category = "Summit Geyser", Meta = (MakeEditWidget))
	FVector LaunchTarget(0.0, 0.0, 1000.0);

	// The upward velocity that the player should end up with once they're at that point
	UPROPERTY(EditAnywhere, Category = "Summit Geyser")
	TPerPlayer<float> LaunchTargetVelocity;
	default LaunchTargetVelocity[EHazePlayer::Mio] = 1000.0;
	default LaunchTargetVelocity[EHazePlayer::Zoe] = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Rumbles & Shakes")
	TSubclassOf<UCameraShakeBase> BuildUpCameraShake;

	UPROPERTY(EditAnywhere, Category = "Rumbles & Shakes")
	float BuildUpCameraShakeMaxDistance = 2500.0;

	UPROPERTY(EditAnywhere, Category = "Rumbles & Shakes")
	float BuildUpRumbleMaxIntensity = 0.5;

	UPROPERTY(EditAnywhere, Category = "Rumbles & Shakes")
	TSubclassOf<UCameraShakeBase> EruptionCameraShake;

	UPROPERTY(EditAnywhere, Category = "Rumbles & Shakes")
	UForceFeedbackEffect EruptionRumble;

	UPROPERTY(EditAnywhere, Category = "Rumbles & Shakes")
	float EruptionRumbleMaxRange = 400.0; 

	UPROPERTY(EditAnywhere, Category = "Rumbles & Shakes")
	float EruptionCameraShakeMaxDistance = 750.0;

	// Whether to automatically erupt based on a timer interval
	UPROPERTY(EditAnywhere, Category = "Timed Eruption")
	bool bTimedEruption = false;

	// Interval between eruptions
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTimedEruption", EditConditionHides), Category = "Timed Eruption")
	float EruptInterval = 3.0;

	// Starting offset of the timer
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTimedEruption", EditConditionHides), Category = "Timed Eruption")
	FHazeRange EruptTimeOffset(0.0, 3.0);

	// Speed up the timed eruption when a player is nearby
	UPROPERTY(EditAnywhere, Category = "Timed Eruption", Meta = (EditCondition = "bTimedEruption", EditConditionHides))
	bool bSpeedUpWhenPlayerNearby = false;

	// How much faster is the eruption interval when a player is standing directly on top of the geyser
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTimedEruption && bSpeedUpWhenPlayerNearby", EditConditionHides, Units = "Times"), Category = "Timed Eruption")
	float NearbyPlayerIntervalSpeedUp = 1.0;

	// How near to the center of the must the player be to be sped up
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTimedEruption && bSpeedUpWhenPlayerNearby", EditConditionHides), Category = "Timed Eruption")
	float NearbyPlayerDistance = 200.0;

	UPROPERTY(EditDefaultsOnly, Category = "VFX")
	FRuntimeFloatCurve ParticleAmountCurve;

	USummitGeyserEvent OnBecameBlocked;
	USummitGeyserEvent OnBecameUnblocked;

	private float BuildUpTimer = 0.0;
	private float EruptTimer = 0.0;
	private bool bIsErupting = false;
	private TArray<FInstigator> EruptionDisablers;
	private TArray<FInstigator> EruptionInstigators;
	TArray<AHazePlayerCharacter> PlayersOnGeyser;
	TPerPlayer<UCameraShakeBase> PlayingBuildUpCameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bTimedEruption)
		{
			if(HasControl())
				CrumbAddInitialRandomEruptionTimerOffset(EruptTimeOffset.Rand());
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbAddInitialRandomEruptionTimerOffset(float Offset)
	{
		BuildUpTimer += Offset;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		if (bTimedEruption && bSpeedUpWhenPlayerNearby)
		{
			auto Sphere = USphereComponent::Create(this);
			Sphere.bIsEditorOnly = true;
			Sphere.IsVisualizationComponent = true;
			Sphere.SphereRadius = NearbyPlayerDistance;
			Sphere.ShapeColor = FColor::Red;
		}
#endif
	}

	UFUNCTION(Category = "Summit Geyser")
	void EnableEruption(FInstigator Instigator)
	{
		EruptionDisablers.Remove(Instigator);
	}

	UFUNCTION(Category = "Summit Geyser")
	void DisableEruption(FInstigator Instigator)
	{
		EruptionDisablers.AddUnique(Instigator);
	}

	UFUNCTION(Category = "Summit Geyser")
	void AddEruptionInstigator(FInstigator Instigator)
	{
		EruptionInstigators.AddUnique(Instigator);
	}

	UFUNCTION(Category = "Summit Geyser")
	void RemoveEruptionInstigator(FInstigator Instigator)
	{
		EruptionInstigators.RemoveSingleSwap(Instigator);
	}

	// Immediately erupt the geyser
	UFUNCTION(Category = "Summit Geyser")
	void Erupt()
	{
		if (bIsErupting)
			return;

		if(!IsEruptionEnabled())
			return;

		GeyserEffect.Activate(true);
		EruptTimer = 0.0;
		bIsErupting = true;

		PlayEruptFeedbackForNearbyPlayers();

		USummitGeyserEventHandler::Trigger_OnStartedErupting(this);
	}

	bool IsInLaunchPlayerThreshold() const
	{
		if(!bTimedEruption)
			return true;

		return EruptTimer > EruptionLaunchDelay;
	}

	UFUNCTION(Category = "Summit Geyser")
	void StopErupting()
	{
		if(!bIsErupting)
			return;

		GeyserEffect.Deactivate();
		bIsErupting = false;
		USummitGeyserEventHandler::Trigger_OnFinishedErupting(this);
	}

	bool IsErupting() const
	{
		return bIsErupting;
	}

	bool IsEruptionEnabled()
	{
		return EruptionDisablers.Num() == 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bTimedEruption
		&& bIsErupting)
			EruptTimer += DeltaSeconds;

		if(HasControl())
		{
			if(bTimedEruption)
			{
				if (bIsErupting)
				{
					if (EruptTimer >= EruptionDuration || !IsEruptionEnabled())
						CrumbTimedStopErupting();
				}
				else
				{
					if(IsEruptionEnabled())
					{
						bool bPlayerNearby = false;
						if (bSpeedUpWhenPlayerNearby)
						{
							for (auto Player : PlayersOnGeyser)
							{
								if (Player.GetDistanceTo(this) < NearbyPlayerDistance)
								{
									bPlayerNearby = true;
									break;
								}
							}
						}

						if (bPlayerNearby)
							BuildUpTimer += DeltaSeconds * NearbyPlayerIntervalSpeedUp;
						else
							BuildUpTimer += DeltaSeconds;

						if (BuildUpTimer >= EruptInterval)
						{
							CrumbStartErupting();
							BuildUpTimer -= EruptInterval;
						}
					}
				}
			}
			else
			{
				if(bIsErupting)
				{
					if(!IsEruptionEnabled()
					|| EruptionInstigators.Num() == 0)
						CrumbStopErupting();
				}
				else
				{
					if(IsEruptionEnabled()
					&& EruptionInstigators.Num() > 0)
						CrumbStartErupting();
				}
			}
		}

		for(auto Instigator : EruptionInstigators)
		{
			TEMPORAL_LOG(this).Value(f"Instigator: {Instigator}", Instigator);
		}
		for(auto Instigator : EruptionDisablers)
		{
			TEMPORAL_LOG(this).Value(f"Disabler: {Instigator}", Instigator);
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbStartErupting()
	{
		Erupt();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbStopErupting()
	{
		StopErupting();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbTimedStopErupting()
	{
		bIsErupting = false;
		EruptTimer = 0.0;
		USummitGeyserEventHandler::Trigger_OnFinishedErupting(this);
	}

	UFUNCTION(BlueprintPure)
	float GetParticleAmountAlpha() const 
	{
		float Alpha;
		if(!bIsErupting)
		{
			Alpha = (BuildUpTimer/EruptInterval) * 0.5;
		}
		else
		{
			Alpha = (EruptTimer/EruptionDuration) + 0.5;
		}

		float ParticleAmount = ParticleAmountCurve.GetFloatValue(Alpha);

		return ParticleAmount;
	}

	float GetEruptionBuildUpAlpha() const
	{
		return Math::Saturate(BuildUpTimer / EruptInterval);
	}

	private void PlayEruptFeedbackForNearbyPlayers()
	{
		for(auto Player : Game::Players)
		{
			float PlayerDistSqrd = ActorLocation.DistSquared(Player.ActorLocation);

			float EruptionCameraShakeMaxDistSqrd = Math::Square(EruptionCameraShakeMaxDistance);
			if(PlayerDistSqrd < EruptionCameraShakeMaxDistSqrd)
				Player.PlayWorldCameraShake(EruptionCameraShake, this, ActorLocation, 0.0, EruptionCameraShakeMaxDistance, 1.0);
			
			float EruptionRumbleMaxRangeSqrd = Math::Square(EruptionRumbleMaxRange);
			if(PlayerDistSqrd < EruptionRumbleMaxRangeSqrd)
				Player.PlayForceFeedback(EruptionRumble, false, true, this);

		}
	}
};