enum ENetworkCrumbTrailState
{
	Normal,
	Buffering,
	FastForward,
};

class UNetworkCrumbTrail : UHazeCrumbTrail
{
	const int MinLengthBucketCount = 20;
	const float MinLengthBucketDuration = 1.0;

	int TrailBufferIntervals = -1;

	TArray<float> CrumbTrailMinLength;
	default CrumbTrailMinLength.SetNumZeroed(MinLengthBucketCount);
	float MinLengthBucketTimer = 0.0;
	int MinLengthBucketIndex = 0.0;

	float TrailPredict_Error = 0.0;

	float MedianPredict_PredictedOtherSideSendTime = 0.0;
	float MedianPredict_DivergenceTimeRemaining = 0.0;
	float MedianPredict_PendingCorrection = 0.0;
	TArray<float> MedianPredict_Divergences;

	ENetworkCrumbTrailState State = ENetworkCrumbTrailState::Buffering;

	/**
	 * The goal of this algorithm is to find:
	 * - The MINIMUM possible wanted buffered trail length, that
	 * - can be CONSISTENTLY maintained given the current network connection stability
	 * 
	 * To do this, whenever our trail length dips too low, we increase the the buffer length.
	 * When we have minimum trail length data for a period of time, we decrease it to match.
	 */
	UFUNCTION(BlueprintOverride)
	void AdvanceReceiveTrail(float32 DeltaTime)
	{
		if (DeltaTime == 0.0)
			return;

		// If we haven't established a crumb trail length at all yet, set a sensible default
		if (TrailBufferIntervals == -1)
		{
#if EDITOR
			// In editor, base the default crumb trail target delay on the configured network latency.
			FHazeNetThrottleOptions Throttle = NetworkDebug::GetCurrentThrottleOptions();
			TrailBufferIntervals = Math::Max(Math::CeilToInt((Throttle.PingVariance * 2.0 / 1000.0) / TrailSyncInterval + 0.5), 3);
#else
			// Otherwise, pick something reasonable-sounding. The trail will adjust it on its own over time.
			TrailBufferIntervals = 3;
#endif
		}

		if (State == ENetworkCrumbTrailState::Normal)
		{
			// If our trail is too short, bump the wanted buffer time and start buffering
			if (TrailLength < DeltaTime - 0.001 && TrailTime >= ReceivedTrailFlushTime)
			{
				State = ENetworkCrumbTrailState::Buffering;
				TrailBufferIntervals += 1;
				TrailSpeed = 0.0;
			}
			else
			{
				// If our trail is too long, speed up until we hit our target
				float MaxBufferLength = (TrailBufferIntervals + 2) * TrailSyncInterval;
				float WantedTrailLength = TrailBufferIntervals * TrailSyncInterval;
				if (TrailLength >= MaxBufferLength - 0.01)
				{
					// We always need to get through the trail in at most 1 second
					TrailSpeed = Math::Max(1.25, 1.0 + (TrailLength - WantedTrailLength));
					State = ENetworkCrumbTrailState::FastForward;
				}
				// Otherwise we're in the sweet spot
				else
				{
					TrailSpeed = 1.0;
				}
			}
		}
		else if (State == ENetworkCrumbTrailState::Buffering)
		{
			// Once we have enough trail, start up again
			float WantedTrailLength = TrailBufferIntervals * TrailSyncInterval;
			if (TrailLength >= WantedTrailLength || TrailTime < ReceivedTrailFlushTime)
			{
				State = ENetworkCrumbTrailState::Normal;
				TrailSpeed = 0.0;
			}
			else
			{
				TrailSpeed = 0.0;
			}
		}
		else if (State == ENetworkCrumbTrailState::FastForward)
		{
			float WantedTrailLength = TrailBufferIntervals * TrailSyncInterval;
			if (TrailLength - (TrailSpeed*DeltaTime) <= WantedTrailLength)
			{
				TrailSpeed = Math::Max((TrailLength - WantedTrailLength) / DeltaTime, 1.0);
				State = ENetworkCrumbTrailState::Normal;
			}
			else
			{
				// We always need to get through the trail in at most 1 second
				TrailSpeed = Math::Max(TrailSpeed, 1.0 + (TrailLength - WantedTrailLength));
			}
		}

		// If we've held a certain length of crumb trail for a long enough time, adapt to the new minimum length
		MinLengthBucketTimer += DeltaTime;
		if (MinLengthBucketTimer > MinLengthBucketDuration)
		{
			MinLengthBucketTimer = 0.0;
			MinLengthBucketIndex = Math::WrapIndex(MinLengthBucketIndex + 1, 0, CrumbTrailMinLength.Num());
			CrumbTrailMinLength[MinLengthBucketIndex] = MAX_flt;
		}

		if (State == ENetworkCrumbTrailState::Buffering)
			CrumbTrailMinLength[MinLengthBucketIndex] = 0.0;
		else
			CrumbTrailMinLength[MinLengthBucketIndex] = Math::Min(CrumbTrailMinLength[MinLengthBucketIndex], TrailLength - DeltaTime + 0.01);

		float RecentMinimum = MAX_flt;
		for (float MinBucket : CrumbTrailMinLength)
			RecentMinimum = Math::Min(RecentMinimum, MinBucket);

		float HeadRoom = RecentMinimum;
		if (HeadRoom > TrailSyncInterval && TrailBufferIntervals > 0)
		{
			TrailBufferIntervals -= Math::FloorToInt(HeadRoom / TrailSyncInterval);
			TrailBufferIntervals = Math::Max(TrailBufferIntervals, 0);
			State = ENetworkCrumbTrailState::FastForward;

			MinLengthBucketTimer = 0.0;
			CrumbTrailMinLength.Reset();
			CrumbTrailMinLength.SetNumZeroed(MinLengthBucketCount);
		}

		// Advance the target time we want to hit this frame
		TrailTargetDelay = TrailBufferIntervals * TrailSyncInterval;
		TrailTargetTime = TrailTime + TrailSpeed * DeltaTime;

		// OLD: TrailPredict:
		//  Uses the crumb trail's current position to predict ahead to where we think the other side's send time is
		//  Is prone to creating error when the ping is very variable
		float TrailPredict_PredictedOtherSideSendTime = 0;
		TrailPredict_Error = Math::FInterpConstantTo(
			TrailPredict_Error,
			TrailTargetDelay + (Network::PingRoundtripSeconds * 0.5 * Time::WorldTimeDilation),
			DeltaTime, 0.1);
		TrailPredict_PredictedOtherSideSendTime = TrailTargetTime + TrailPredict_Error;

		// NEW: MedianPredict
		//  Prediction always increases by deltatime, and adapts to the median predicted error over time
		MedianPredict_PredictedOtherSideSendTime += DeltaTime;

		// If we are currently working out a prediction divergence, do so
		float MedianPredict_AppliedCorrection = 0.0;
		float MaxCorrectionSizeToApply = Math::Max(DeltaTime * 0.05, Math::Abs(MedianPredict_PendingCorrection) * DeltaTime);

		if (MedianPredict_PendingCorrection != 0.0)
		{
			if (Math::Abs(MedianPredict_PendingCorrection) > 1.0)
			{
				// If we're off by a LOT, assume something froze the game on the other side and teleport the prediction
				MedianPredict_AppliedCorrection = MedianPredict_PendingCorrection;
				MedianPredict_PendingCorrection = 0.0;
				MedianPredict_PredictedOtherSideSendTime += MedianPredict_AppliedCorrection;
			}
			else if (Math::Abs(MedianPredict_PendingCorrection) < MaxCorrectionSizeToApply)
			{
				MedianPredict_AppliedCorrection = MedianPredict_PendingCorrection;
				MedianPredict_PendingCorrection = 0.0;
				MedianPredict_PredictedOtherSideSendTime += MedianPredict_AppliedCorrection;
			}
			else
			{
				MedianPredict_AppliedCorrection = Math::Clamp(MedianPredict_PendingCorrection, -MaxCorrectionSizeToApply, MaxCorrectionSizeToApply);
				MedianPredict_PendingCorrection -= MedianPredict_AppliedCorrection;
				MedianPredict_PredictedOtherSideSendTime += MedianPredict_AppliedCorrection;
			}
		}

		// Compute the median divergence every 2 seconds
		float MedianPredict_RawPrediction = LatestDataReceiveTrailTime + GameTimeSinceLatestDataReceived + Network::PingRoundtripSeconds * 0.5 * Time::WorldTimeDilation;
		float MedianPredict_RawDivergence = MedianPredict_RawPrediction - (MedianPredict_PredictedOtherSideSendTime + MedianPredict_PendingCorrection);

		MedianPredict_Divergences.Add(MedianPredict_RawDivergence);
		MedianPredict_DivergenceTimeRemaining += DeltaTime;
		if (MedianPredict_DivergenceTimeRemaining > 2.0)
		{
			MedianPredict_Divergences.Sort();
			int MiddleIndex = Math::IntegerDivisionTrunc(MedianPredict_Divergences.Num(), 2);

			float MedianPredict_MedianDivergence = MedianPredict_Divergences[Math::Clamp(MiddleIndex, 0, MedianPredict_Divergences.Num() - 1)];
			MedianPredict_PendingCorrection += MedianPredict_MedianDivergence;

			// Small errors are ignored here to prevent bouncing up and down
			if (Math::Abs(MedianPredict_PendingCorrection) < Math::Min(1.0 / 60.0, Network::PingOneWaySeconds * 0.5))
				MedianPredict_PendingCorrection = 0.0;

			MedianPredict_Divergences.Reset();
			MedianPredict_DivergenceTimeRemaining = 0.0;
		}

		// Don't allow the prediction to go below the latest data, that's always wrong
		if (MedianPredict_PredictedOtherSideSendTime < LatestDataReceiveTrailTime)
			MedianPredict_PredictedOtherSideSendTime = MedianPredict_RawPrediction;

		// Select between old and new prediction
		PredictedOtherSideSendTime = MedianPredict_PredictedOtherSideSendTime;

		#if !RELEASE
		if (Network::IsGameNetworked())
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG("/Network");

			TemporalLog
				.Value("Crumb Trail;TrailTime", TrailTime)
				.Value("Crumb Trail;Length", TrailLength)
				.Value("Crumb Trail;CrumbCount", GetCrumbCount())
				.Value("Crumb Trail;TargetDelay", TrailTargetDelay)
				.Value("Crumb Trail;TrailLengthAfterAdvance", (TrailTime + TrailLength) - TrailTargetTime)
				.Value("Crumb Trail;HeadRoom", HeadRoom)
				.Value("Crumb Trail;Speed", TrailSpeed)
				.Value("Crumb Trail;TargetTime", TrailTargetTime)
				.Value("Crumb Trail;SendTime", SendTime)
				.Value("Crumb Trail;LatestDataTime", TrailTime + TrailLength)
				.CustomStatus("Crumb Trail;State", f"{State}")
				.Value("Crumb Trail;PredictedOtherSideSendTime", PredictedOtherSideSendTime)
				.Value("Crumb Trail;PredictedTrailError", TrailPredict_Error)
				.Value("Conditions;PingRoundtripSeconds", Network::GetPingRoundtripSeconds())
				.Value("Crumb Trail;SentTrailFlushTime", SentTrailFlushTime)
				.Value("Crumb Trail;ReceivedTrailFlushTime", ReceivedTrailFlushTime)

				.Value("Crumb Trail;TrailPredict;PredictedOtherSideSendTime", TrailPredict_PredictedOtherSideSendTime)
				.Value("Crumb Trail;MedianPredict;PredictedOtherSideSendTime", MedianPredict_PredictedOtherSideSendTime)
				.Value("Crumb Trail;MedianPredict;RawPrediction", MedianPredict_RawPrediction)
				.Value("Crumb Trail;MedianPredict;RawDivergence", MedianPredict_RawDivergence)
				.Value("Crumb Trail;MedianPredict;PendingCorrection", MedianPredict_PendingCorrection)
				.Value("Crumb Trail;MedianPredict;AppliedCorrection", MedianPredict_AppliedCorrection)
			;

			float PacketLoss = Debug::GetConnectionPacketLoss();
			if (PacketLoss > 0.0)
			{
				TemporalLog
					.Value("Conditions;PacketLoss", Debug::GetConnectionPacketLoss())
				;
			}

#if EDITOR
			auto OtherSide = Cast<UNetworkCrumbTrail>(Debug::GetPIENetworkOtherSideForDebugging(this));
			if (OtherSide != nullptr)
			{
				TemporalLog
					.Value("Crumb Trail;ActualOtherSideSendTime", OtherSide.SendTime)
					.Value("Crumb Trail;PrePredictionError", Math::Abs(TrailTime - OtherSide.SendTime))
					.Value("Crumb Trail;TrailPredict;PostPredictionError", Math::Abs(OtherSide.SendTime - TrailPredict_PredictedOtherSideSendTime))
					.Value("Crumb Trail;MedianPredict;PostPredictionError", Math::Abs(OtherSide.SendTime - MedianPredict_PredictedOtherSideSendTime))
					.Value("Crumb Trail;MedianPredict;RawPredictionError", Math::Abs(OtherSide.SendTime - MedianPredict_RawPrediction))
				;
			}
#endif
		}
		#endif
	}
};