class AEvergreenSpikeTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeMovablePlayerTriggerComponent PlayerTriggerComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedAlpha;
	default SyncedAlpha.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager Manager;

	UPROPERTY(EditAnywhere)
	bool bIsStatic = false;

	UPROPERTY(EditAnywhere)
	bool bAllowSmallAndPlayerToPassThrough = true;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveTimeLike;

	UPROPERTY(EditDefaultsOnly)
	float TimeLikePlayRate = 3.0;

	UPROPERTY(EditDefaultsOnly)
	float Distance = 250.0;

	/* When predicting the movement on Zoe's side */
	UPROPERTY(EditDefaultsOnly)
	float PredictionExtendDuration = 3.0;

	UPROPERTY(NotVisible, Transient, BlueprintReadWrite)
	float CurrentTimelineTime;

	UPROPERTY(NotVisible, Transient, BlueprintReadWrite)
	bool bShouldStartExtended = false;

	UPROPERTY(EditAnywhere, Category = "Death Effect")
	TSubclassOf<UDeathEffect> SpikeDeath;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackForMio;

	private bool bIsDangerous = false;
	private FVector OriginalStartLocation;
	private bool bCurrentlyPredicting = false;
	private bool bPredictingActivation = false;
	private float TimeOfStartPredicting;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalStartLocation = Mesh.RelativeLocation;

		if (Manager != nullptr)
		{
			Manager.LifeComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"TriggerStartInteract");
			Manager.LifeComp.OnInteractStopDuringLifeGive.AddUFunction(this, n"TriggerStopInteract");
			Manager.OnNetInteractStartDuringLifeGive.AddUFunction(this, n"OnNetStartInteract");
			Manager.OnNetInteractStopDuringLifeGive.AddUFunction(this, n"OnNetStopInteract");
		}

		MoveTimeLike.BindUpdate(this, n"OnTimeLikeUpdate");
		MoveTimeLike.SetPlayRate(TimeLikePlayRate);
		SetActorControlSide(Game::Mio);

		SyncedAlpha.Value = 0.0;

		PlayerTriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		PlayerTriggerComp.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
		ImpactCallbackComp.OnAnyImpactByPlayer.AddUFunction(this, n"OnAnyImpactByPlayer");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!HasControl())
			RemoteMove();

		UpdateIsDangerous();

		if(bIsDangerous)
		{
			for(auto PlayerInTrigger : PlayerTriggerComp.PlayersInTrigger)
			{
				if(!PlayerInTrigger.HasControl())
					continue;

				if(!bAllowSmallAndPlayerToPassThrough)
				{
					PlayerInTrigger.KillPlayer(DeathEffect = SpikeDeath);
					continue;
				}

				auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(PlayerInTrigger);
				if(ShapeShiftComp.IsBigShape())
					PlayerInTrigger.KillPlayer(DeathEffect = SpikeDeath);
			}
		}
	}

	private void RemoteMove()
	{
		FVector Location = GetRelativeLocationFromMoveAlpha(SyncedAlpha.Value);
		if(bCurrentlyPredicting)
		{
			float TimeSince = Time::GetGameTimeSince(TimeOfStartPredicting);
			float Alpha = Math::Saturate(TimeSince / PredictionExtendDuration);
			FVector Target = StartTargetLocation;
			if(!bPredictingActivation)
			{
				Alpha = 1.0 - Alpha;
				Target = StopTargetLocation;
			}

			float MoveAlpha = MoveTimeLike.Curve.GetFloatValue(Alpha);
			FVector PredictedLocation = GetRelativeLocationFromMoveAlpha(MoveAlpha);
			if(Location.DistSquared(Target) < PredictedLocation.DistSquared(Target))
			{
				bCurrentlyPredicting = false;
			}
			else
			{
				Location = PredictedLocation;
			}
		}

		Mesh.RelativeLocation = Location;
	}

	private void UpdateIsDangerous()
	{
		if(Mesh.RelativeLocation.Z > -120)
		{
			if(bIsDangerous)
			{
				// Not extended enough to actually kill
				AddActorCollisionBlock(this);
				PlayerTriggerComp.DisableTrigger(this);
				bIsDangerous = false;
			}
		}
		else
		{
			if(!bIsDangerous)
			{
				// Extended
				RemoveActorCollisionBlock(this);
				PlayerTriggerComp.EnableTrigger(this);
				bIsDangerous = true;
			}
		}
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		if(!bAllowSmallAndPlayerToPassThrough)
		{
			// Just kill everyone!
			Player.KillPlayer(DeathEffect = SpikeDeath);
			return;
		}

		auto ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		if(ShapeShiftComp != nullptr)
		{
			if(ShapeShiftComp.IsBigShape())
			{
				// Big shape can never just pass through the spikes
				Player.KillPlayer(DeathEffect = SpikeDeath);
				return;
			}
		}

		auto IgnoreComp = UTundraPlayerShapeshiftingIgnoreCollisionContainerComponent::Get(Player);
		IgnoreComp.ActorsToIgnore.Add(this);
	}
	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		auto IgnoreComp = UTundraPlayerShapeshiftingIgnoreCollisionContainerComponent::Get(Player);
		IgnoreComp.ActorsToIgnore.Remove(this);
	}

	UFUNCTION()
	private void OnAnyImpactByPlayer(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		Player.KillPlayer(DeathEffect = SpikeDeath);
	}

	UFUNCTION()
	private void OnPlayerInsideChangeShape(AHazePlayerCharacter Player, ETundraShapeshiftShape NewShape)
	{
		if(NewShape == ETundraShapeshiftShape::Big)
		{
			Player.KillPlayer(DeathEffect = SpikeDeath);
		}
	}

	UFUNCTION()
	private void OnTimeLikeUpdate(float CurrentValue)
	{
		if(!HasControl())
			return;

		FVector RelativeLocation = GetRelativeLocationFromMoveAlpha(CurrentValue);
		Mesh.RelativeLocation = RelativeLocation;
		SyncedAlpha.Value = CurrentValue;
	}

	UFUNCTION(BlueprintCallable)
	void TriggerStartInteract()
	{
		if(bIsStatic)
			return;

		ForceFeedback::PlayWorldForceFeedback(ForceFeedbackForMio, ActorLocation, true, this, 200, 700);

		if(Network::IsGameNetworked() && HasControl())
			return;

		bCurrentlyPredicting = true;
		bPredictingActivation = true;
		TimeOfStartPredicting = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintCallable)
	void TriggerStopInteract()
	{
		if(bIsStatic)
			return;

		ForceFeedback::PlayWorldForceFeedback(ForceFeedbackForMio, ActorLocation, true, this, 200, 700);

		if(Network::IsGameNetworked() && HasControl())
			return;

		bCurrentlyPredicting = true;
		bPredictingActivation = false;
		TimeOfStartPredicting = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	private void OnNetStartInteract()
	{
		if(!HasControl())
			return;

		MoveTimeLike.Play();
	}

	UFUNCTION()
	private void OnNetStopInteract()
	{
		if(!HasControl())
			return;

		MoveTimeLike.Reverse();
	}

	private FVector GetStopTargetLocation() const property
	{
		return OriginalStartLocation;
	}

	private FVector GetStartTargetLocation() const property
	{
		return FVector(0.0, 0.0, Distance * (bShouldStartExtended ? 1.0 : -1.0));
	}

	private FVector GetRelativeLocationFromMoveAlpha(float Alpha) const
	{
		return Math::Lerp(StopTargetLocation, StartTargetLocation, Alpha);
	}
}