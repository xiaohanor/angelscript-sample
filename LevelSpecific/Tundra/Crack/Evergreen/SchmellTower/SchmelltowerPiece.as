event void FSchmellTowerPieceStartMoveEvent(ASchmelltowerPiece Piece, bool bIsExtending);
event void FSchmellTowerPieceStopMoveEvent(ASchmelltowerPiece Piece, bool bIsExtended);

class ASchmelltowerPiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedAlpha;
	default SyncedAlpha.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.0;

	UPROPERTY(EditAnywhere)
	bool bDoNotMove = false;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FVector GoToLocation = FVector(600.0, 0.0, 0.0);

	UPROPERTY(EditAnywhere)
	bool bStartAtGoToLocation = false;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveTimeLike;

	UPROPERTY(EditDefaultsOnly)
	float TimeLikePlayRate = 1.5;

	/* When predicting the movement on Zoe's side */
	UPROPERTY(EditDefaultsOnly)
	float PredictionExtendDuration = 4.0;

	UPROPERTY()
	FSchmellTowerPieceStartMoveEvent OnStartMoving;

	UPROPERTY()
	FSchmellTowerPieceStopMoveEvent OnStopMoving;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackForMio;

	private FVector OriginalStartLocation;
	private bool bCurrentlyPredicting = false;
	private bool bPredictingActivation = false;
	private float TimeOfStartPredicting;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalStartLocation = BaseMesh.RelativeLocation;

		MoveTimeLike.BindUpdate(this, n"OnTimeLikeUpdate");
		MoveTimeLike.BindFinished(this, n"OnTimeLikeFinished");
		MoveTimeLike.SetPlayRate(TimeLikePlayRate);
		SetActorControlSide(Game::Mio);

		SyncedAlpha.Value = 0.0;
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
			FVector Target = ActivateTargetLocation;
			if(!bPredictingActivation)
			{
				Alpha = 1.0 - Alpha;
				Target = DeactivateTargetLocation;
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

		BaseMesh.RelativeLocation = Location;
	}

	UFUNCTION()
	private void OnTimeLikeUpdate(float CurrentValue)
	{
		if(!HasControl())
			return;

		FVector RelativeLocation = GetRelativeLocationFromMoveAlpha(CurrentValue);
		BaseMesh.RelativeLocation = RelativeLocation;
		SyncedAlpha.Value = CurrentValue;
	}

	UFUNCTION()
	private void OnTimeLikeFinished()
	{
		if(!HasControl())
			return;

		bool bIsExtended = !MoveTimeLike.IsReversed();
		if(bStartAtGoToLocation)
			bIsExtended = !bIsExtended;

		CrumbOnTimeLikeFinished(bIsExtended);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnTimeLikeFinished(bool bIsExtended)
	{
		OnStopMoving.Broadcast(this, bIsExtended);
	}

	UFUNCTION(BlueprintCallable)
	void TriggerActivatePlatform()
	{
		if(bDoNotMove)
			return;

		ForceFeedback::PlayWorldForceFeedback(ForceFeedbackForMio, ActorLocation, true, this, 300, 1500);
		PrintToScreen("MMIMIMIMIMI", 2);

		OnStartMoving.Broadcast(this, !bStartAtGoToLocation);

		if(Network::IsGameNetworked() && HasControl())
			return;

		bCurrentlyPredicting = true;
		bPredictingActivation = true;
		TimeOfStartPredicting = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintCallable)
	void TriggerDeactivatePlatform()
	{
		if(bDoNotMove)
			return;

		ForceFeedback::PlayWorldForceFeedback(ForceFeedbackForMio, ActorLocation, true, this, 300, 1500);
		PrintToScreen("HOHO", 2);

		OnStartMoving.Broadcast(this, bStartAtGoToLocation);

		if(Network::IsGameNetworked() && HasControl())
			return;

		bCurrentlyPredicting = true;
		bPredictingActivation = false;
		TimeOfStartPredicting = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	void OnNetActivatePlatform()
	{
		if(!HasControl())
			return;

		MoveTimeLike.Play();
	}

	UFUNCTION()
	void OnNetDeactivatePlatform()
	{
		if(!HasControl())
			return;

		MoveTimeLike.Reverse();
	}

	private FVector GetDeactivateTargetLocation() const property
	{
		return OriginalStartLocation;
	}

	private FVector GetActivateTargetLocation() const property
	{
		return bStartAtGoToLocation ? FVector::ZeroVector : GoToLocation;
	}

	private FVector GetRelativeLocationFromMoveAlpha(float Alpha) const
	{
		return Math::Lerp(DeactivateTargetLocation, ActivateTargetLocation, Alpha);
	}
}