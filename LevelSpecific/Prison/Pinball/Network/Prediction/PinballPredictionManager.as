delegate float FPinballPredictionDurationDelegate();
event void FPinballPredictionPreRollback();
event void FPinballPredictionPerformRollback(uint InFrameNumber, float InPredictionTime);
event void FPinballPredictionPostRollback();
event void FPinballPredictionInit(uint InFrameNumber, float InPredictionTime);
event void FPinballPredictionTick(uint InFrameNumber, uint InSubframeNumber, float InPredictionTime, float InDeltaTime);
event void FPinballPredictionFinalize(float InPredictionTime);

namespace Pinball::Prediction
{
	APinballPredictionManager GetManager()
	{
		check(Network::IsGameNetworked());
		check(Pinball::GetPaddlePlayer().HasControl());
		
		auto Manager = TListedActors<APinballPredictionManager>().Single;
		
		if(Manager == nullptr)
			Manager = APinballPredictionManager::Spawn();

		return Manager;
	}

	/**
	 * Are we in a networked game, where Zoe is remote? This means that we should be predicting where Zoe is.
	 */
	bool IsPredictedGame()
	{
		if(!Network::IsGameNetworked())
			return false;

		auto BallPlayer = Pinball::GetBallPlayer();
		if(BallPlayer == nullptr)
			return false;

		if(BallPlayer.HasControl())
			return false;

		return true;
	}

	bool IsInsidePredictionLoop()
	{
		if(!IsPredictedGame())
			return false;

		const APinballPredictionManager Manager = GetManager();
		if(Manager == nullptr)
			return false;

		return Manager.bIsPredicting;
	}

	float GetPredictionLoopStartTime()
	{
		check(IsInsidePredictionLoop());
		return GetManager().PredictionLoopStartTime;
	}

	float GetPredictionLoopEndTime()
	{
		check(IsInsidePredictionLoop());
		return GetManager().PredictionLoopEndTime;
	}

	float GetPredictionLoopDuration()
	{
		check(IsInsidePredictionLoop());
		return GetManager().PredictionLoopDuration;
	}
};

UCLASS(NotBlueprintable)
class APinballPredictionManager : AHazeActor
{
	access PredictionComp = private, UPinballPredictionComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UPinballPredictionManagerCapability);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	bool bIsPredicting = false;

	// Where in time our prediction starts, which is where our latest received data from the other side is
	float PredictionLoopStartTime;

	// The prediction time where we believe the other side is right now
	float PredictionLoopEndTime;

	// The time difference between PredictionStartTime and PredictionEndTime
	float PredictionLoopDuration;

	const int MaxSubframes = 20;
	const float MinPredictionDuration = 0.2;

	// Defaulted to true, and set to false from HackablePinball
	TInstigated<bool> bUseCrumbSyncedMovement;
	default bUseCrumbSyncedMovement.DefaultValue = true;

	access:PredictionComp TArray<UPinballPredictionComponent> PredictionComponents;

	FPinballPredictionPreRollback PreRollback;
	FPinballPredictionPerformRollback PerformRollback;
	FPinballPredictionPostRollback PostRollback;

	FPinballPredictionInit PreInit;
	FPinballPredictionInit PostInit;

	FPinballPredictionTick PreSubTick;
	FPinballPredictionTick PostSubTick;

	FPinballPredictionFinalize PreFinalize;
	FPinballPredictionFinalize PostFinalize;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Pinball::GetBallPlayer());

		if(HasControl())
		{
			// We are only needed on the remote side, doing the prediction
			DestroyActor();
		}
	}

	void Predict()
	{
		check(Network::IsGameNetworked());
		check(Pinball::GetPaddlePlayer().HasControl());

		PredictionLoopDuration = -1;

		// Separate array, since not all components may want to be predicting this frame
		TArray<UPinballPredictionComponent> PredictingComponents;

		for(UPinballPredictionComponent PredictionComp : PredictionComponents)
		{
			// Before we calculate the prediction duration, we must have valid latest synced positions
			if(!PredictionComp.UpdateLatestAvailableActorPosition())
				continue;

			// Get the prediction that needs the longest duration
			const float PredictionDuration = PredictionComp.GetPredictionDuration();
			if(PredictionDuration < 0)
				continue;

			PredictionLoopDuration = Math::Max(PredictionDuration, PredictionLoopDuration);
			PredictingComponents.Add(PredictionComp);
		}

		float TimeStep = 1.0 / Pinball::Prediction::PredictedFramesPerSecond;

		if(Math::IsNearlyEqual(PredictionLoopDuration, -1))
		{
			// Nobody wants to predict :c
			return;
		}
		else if(PredictionLoopDuration < KINDA_SMALL_NUMBER)
		{
			// We want to predict, but our duration is extremely low
			return;
		}
		else if(Math::FloorToInt(PredictionLoopDuration / TimeStep) > MaxSubframes)
		{
			// We require more subframes than we allow. Change the time step so that we still cover the entire duration
			TimeStep = PredictionLoopDuration / MaxSubframes;
		}

		PredictionLoopEndTime = Time::OtherSideCrumbTrailSendTimePrediction;
		PredictionLoopStartTime = PredictionLoopEndTime - PredictionLoopDuration;

		const uint FrameNumber = Time::FrameNumber;

		PreRollback.Broadcast();
		PerformRollback.Broadcast(FrameNumber, PredictionLoopStartTime);
		PostRollback.Broadcast();

		PreInit.Broadcast(FrameNumber, PredictionLoopStartTime);

		for(UPinballPredictionComponent PredictionComp : PredictingComponents)
			PredictionComp.Init(FrameNumber, PredictionLoopStartTime, PredictionLoopEndTime);

		PostInit.Broadcast(FrameNumber, PredictionLoopStartTime);

		uint SubframeNumber = 1;
		float PredictionTime = PredictionLoopStartTime;

		while(PredictionTime < PredictionLoopEndTime && SubframeNumber < uint(MaxSubframes))
		{
			const float DeltaTime = Math::Min(TimeStep, PredictionLoopEndTime - PredictionTime);

			PreSubTick.Broadcast(FrameNumber, SubframeNumber, PredictionTime, DeltaTime);

			for(UPinballPredictionComponent PredictionComp : PredictingComponents)
				PredictionComp.SubTick(FrameNumber, SubframeNumber, PredictionTime, DeltaTime);

			PostSubTick.Broadcast(FrameNumber, SubframeNumber, PredictionTime, DeltaTime);

			PredictionTime += DeltaTime;
			SubframeNumber += 1;
		}

#if EDITOR
		for(UPinballPredictionComponent PredictionComp : PredictingComponents)
			check(PredictionComp.LastSubTickFrame == FrameNumber, f"{PredictionComp} never performed a prediction tick!");
#endif

		PreFinalize.Broadcast(PredictionTime);

		for(UPinballPredictionComponent PredictionComp : PredictingComponents)
			PredictionComp.Finalize();

		PostFinalize.Broadcast(PredictionTime);
	}
};