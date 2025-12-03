/**
 * Any actors in control of the prediction should implement this component.
 * The actor with the highest PredictionDuration will decide when the prediction starts in the past.
 */
UCLASS(Abstract)
class UPinballPredictionComponent : UActorComponent
{
	uint LastSubTickFrame = 0;
	bool bHasEverReceivedAnyData = false;

	protected UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;
	protected FHazeSyncedActorPosition LatestActorPosition;
	protected float LatestCrumbTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SyncedPositionComp = UHazeCrumbSyncedActorPositionComponent::Get(Owner);
		
		if(HasControl())
			return;

		Pinball::Prediction::GetManager().PredictionComponents.Add(this);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballPrediction");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if(HasControl())
			return;

		Pinball::Prediction::GetManager().PredictionComponents.AddUnique(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if(HasControl())
			return;

		Pinball::Prediction::GetManager().PredictionComponents.RemoveSingle(this);
	}

	/**
	 * Update the latest actor position from the control side synced position.
	 * Might be modified during launches and sync point.
	 * @return false if we have not received any position data yet.
	 */
	bool UpdateLatestAvailableActorPosition()
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "UpdateLatestAvailableActorPosition");
#endif

		if(!SyncedPositionComp.HasAnyDataInCrumbTrail())
		{
			// We have yet to receive any crumb data from Zoe
#if !RELEASE
			TemporalLog.Status("No data in crumb trail!", FLinearColor::Red);
#endif
			return false;
		}

		bHasEverReceivedAnyData = true;

		if(SyncedPositionComp.HasUsableDataInCrumbTrail())
		{
			SyncedPositionComp.GetLatestAvailableData(LatestActorPosition, LatestCrumbTime);

#if !RELEASE
			TemporalLog.Status("Usable data in crumb trail", FLinearColor::Green);
#endif
			return true;
		}
		else
		{
			// Only use the crumb time if we are transitioning
			FHazeSyncedActorPosition SyncedActorPosition;
			SyncedPositionComp.GetLatestAvailableData(SyncedActorPosition, LatestCrumbTime);

#if !RELEASE
			TemporalLog.Status("No usable data in crumb trail!", FLinearColor::Yellow);
#endif
			return true;
		}
	}

	void Init(uint InFrameNumber, float InPredictionLoopStartTime, float InPredictionLoopEndTime)
	{
	}

	bool SubTick(uint InFrameNumber, uint InSubframeNumber, float InPredictionTime, float InDeltaTime)
	{
		LastSubTickFrame = InFrameNumber;
		return true;
	}

	void Finalize()
	{
	}

	bool TryGetLatestAvailableActorPosition(FHazeSyncedActorPosition&out OutActorPosition, float&out OutCrumbTime) const
	{
		OutActorPosition = LatestActorPosition;
		OutCrumbTime = LatestCrumbTime;

		if(!bHasEverReceivedAnyData)
			return false;

		return true;
	}

	float GetPredictionDuration() const
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "GetPredictionDuration");
		TemporalLog.Value("Time Dilation", Time::WorldTimeDilation);
		TemporalLog.Value("bHasEverReceivedAnyData", bHasEverReceivedAnyData);
#endif

		if(!bHasEverReceivedAnyData)
		{
#if !RELEASE
			TemporalLog.Status("No received data!", FLinearColor::Red);
			TemporalLog.Value("PredictDuration", -1);
#endif

			return -1;
		}

		FHazeSyncedActorPosition ActorPosition;
		float CrumbTime = 0;
		TryGetLatestAvailableActorPosition(ActorPosition, CrumbTime);

		const float OtherSideCrumbTrailSendTimePrediction = Time::OtherSideCrumbTrailSendTimePrediction;
		const float PredictDuration = (OtherSideCrumbTrailSendTimePrediction - CrumbTime);

#if !RELEASE
		if(PredictDuration > 0)
			TemporalLog.Status("Valid prediction duration.", FLinearColor::Green);
		else
			TemporalLog.Status("No prediction duration, prediction is disabled for this actor!", FLinearColor::Yellow);

		TemporalLog.Struct("ActorPosition;", ActorPosition);
		TemporalLog.Value("CrumbTime", CrumbTime);
		TemporalLog.Value("OtherSideCrumbTrailSendTimePrediction", OtherSideCrumbTrailSendTimePrediction);
		TemporalLog.Value("PredictDuration", PredictDuration);
#endif

		return PredictDuration;
	}

	void FillLatestActorPositionWithLocal()
	{
		LatestActorPosition.WorldLocation = Owner.ActorLocation;
		LatestActorPosition.ControlOriginalWorldLocation = Owner.ActorLocation;
		LatestActorPosition.ControlOriginalWorldRotation = Owner.ActorRotation;
		LatestActorPosition.WorldRotation = Owner.ActorRotation;
		LatestActorPosition.WorldVelocity = FVector::ZeroVector;
		LatestActorPosition.MovementInput = FVector::ZeroVector;
		LatestActorPosition.RelativeType = EHazeActorPositionRelativeType::WorldLocation;

#if !RELEASE
		TEMPORAL_LOG(this).Event("FillLatestActorPositionWithLocal")
			.Transform("WorldTransform", FTransform(Owner.ActorRotation, Owner.ActorLocation))
		;
#endif
	}
};