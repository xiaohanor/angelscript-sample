class AEvergreenSpinlogPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

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

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveTimeLike;

	UPROPERTY(EditDefaultsOnly)
	float TimeLikePlayRate = 1.6;

	UPROPERTY(EditDefaultsOnly)
	float Distance = 3500.0;

	/* When predicting the movement on Zoe's side */
	UPROPERTY(EditDefaultsOnly)
	float PredictionExtendDuration = 3.0;

	UPROPERTY(NotVisible, Transient, BlueprintReadWrite)
	float CurrentTimelineTime;

	UPROPERTY(NotVisible, Transient, BlueprintReadWrite)
	bool bShouldStartExtended = false;

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

		MoveTimeLike.BindFinished(this, n"TimelikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
			return;

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

	UFUNCTION()
	private void OnTimeLikeUpdate(float CurrentValue)
	{
		if(!HasControl())
			return;

		FVector RelativeLocation = GetRelativeLocationFromMoveAlpha(CurrentValue);
		Mesh.RelativeLocation = RelativeLocation;
		SyncedAlpha.Value = CurrentValue;
	}

	UFUNCTION()
	private void TimelikeFinished()
	{
		Mesh.AddTag(ComponentTags::InheritHorizontalMovementIfGround);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerStartInteract()
	{
		if(bIsStatic)
			return;

		if(Network::IsGameNetworked() && HasControl())
			return;

		bCurrentlyPredicting = true;
		bPredictingActivation = true;
		TimeOfStartPredicting = Time::GetGameTimeSeconds();
		Mesh.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerStopInteract()
	{
		if(bIsStatic)
			return;

		if(Network::IsGameNetworked() && HasControl())
			return;

		bCurrentlyPredicting = true;
		bPredictingActivation = false;
		TimeOfStartPredicting = Time::GetGameTimeSeconds();
		Mesh.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
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
		return FVector(Distance * (bShouldStartExtended ? 1.0 : -1.0), 0.0, 0.0);
	}

	private FVector GetRelativeLocationFromMoveAlpha(float Alpha) const
	{
		return Math::Lerp(StopTargetLocation, StartTargetLocation, Alpha);
	}
}