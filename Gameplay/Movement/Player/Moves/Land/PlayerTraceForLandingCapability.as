class UPlayerTraceForLandingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);
	default CapabilityTags.Add(PlayerMovementTags::LandingApexDive);

	default CapabilityTags.Add(BlockedWhileIn::Dash);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::ShapeShiftForm);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 10;

	UPlayerAirMotionComponent AirMotionComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;

	float PredictedHitAtTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MoveComp.IsInAir())
			return false;

		if (MoveComp.HasCustomMovementStatus(n"Perching"))
			return false;

		if (PoleClimbComp.State != EPlayerPoleClimbState::Inactive && PoleClimbComp.State != EPlayerPoleClimbState::JumpOut)
			return false;

		if(MoveComp.VerticalVelocity.GetSafeNormal().DotProduct(MoveComp.WorldUp) > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MoveComp.IsInAir())
			return true;

		if (MoveComp.HasCustomMovementStatus(n"Perching"))
			return true;

		if (PoleClimbComp.State != EPlayerPoleClimbState::Inactive)
			return true;

		if(MoveComp.VerticalVelocity.GetSafeNormal().DotProduct(MoveComp.WorldUp) > 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

#if !RELEASE
		if(IsDebugActive())
			PrintToScreen("TimeSincePredicted: " + (Time::GameTimeSeconds - PredictedHitAtTime), 5);
#endif

		AirMotionComp.AirMotionData.CurrentPredictedDiveHit = FHitResult();
		PredictedHitAtTime = 0;
		
		AirMotionComp.AnimData.bHighVelocityLandingDetected = false;
		AirMotionComp.AnimData.bDiving = false;
		AirMotionComp.AirMotionData.bDiveDetected = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			//Trace for a Landing / Dive once we start descending
			if(MoveComp.VerticalVelocity.GetSafeNormal().DotProduct(MoveComp.WorldUp) <= 0)
				TraceAheadForContextualMove();
			else
			{
				if(PredictedHitAtTime > 0)
				{
					//If we are ascending then just clear any stored data
					PredictedHitAtTime = 0;
					AirMotionComp.AnimData.bHighVelocityLandingDetected = false;
					AirMotionComp.AirMotionData.bDiveDetected = false;
				}
			}
		}
	}

	void TraceAheadForContextualMove()
	{
#if !RELEASE
		FTemporalLog Log = TEMPORAL_LOG(this).Section("Landing Trace");
#endif
		const int TraceResolution = 3;
		// [AL] Increased the prediction window for Landing slightly to get a better curvature curve with lower resolution.
		// No overall increase in trace distance or duration, just 2 of the 3 traces will cover the landing portion with some curvature
		const float TIME_HIGHSPEEDLANDING = 0.45;
		const float TIME_SWIMMING_DIVE = 0.6;
		float CurrTimeStep = 0;

		FVector DeltaMovement;
		FVector NewVelocity;
		
		FHazeTraceSettings PredictionTrace = Trace::InitFromMovementComponent(MoveComp);
		PredictionTrace.UseShapeWorldOffset(FVector::ZeroVector);
		PredictionTrace.UseLine();

#if !RELEASE
		if(IsDebugActive())
			PredictionTrace.DebugDrawOneFrame();
#endif

		FVector TraceStart = Player.ActorLocation;
		FVector TraceEnd;

		for (int i = 0; i < TraceResolution; i++)
		{
			if(i != 0)
			{
				TraceStart = TraceEnd;
			}

			//Manually set the TimeStep window since its no longer uniform (to work better with lower resolution)
			if (i < TraceResolution - 1)
				CurrTimeStep += TIME_HIGHSPEEDLANDING / 2;
			else
				CurrTimeStep = TIME_SWIMMING_DIVE;

#if !RELEASE
			Log.Value("TimeStep", CurrTimeStep);
#endif	
			AirMotionComp.PredictAirMotion(CurrTimeStep, MoveComp.Velocity, MoveComp.MovementInput, DeltaMovement, NewVelocity);
			TraceEnd = Player.ActorLocation + DeltaMovement;
			FHitResultArray PredictionHits = PredictionTrace.QueryTraceMultiUntilBlock(TraceStart, TraceEnd);

			if(PredictionHits.bHasBlockingHit && !PredictionHits.FirstBlockHit.Component.HasTag(n"Walkable"))
			{
#if !RELEASE
				Log.HitResults("Blocked Unwalkable Trace: " + i, PredictionHits.FirstBlockHit, PredictionTrace.Shape, PredictionTrace.ShapeWorldOffset);
#endif
				//We had a blocking hit but it was unwalkable
				PredictedHitAtTime = 0;
				AirMotionComp.AnimData.bHighVelocityLandingDetected = false;
#if !RELEASE
				Log.Value("HighSpeedLanding Detected", AirMotionComp.AnimData.bHighVelocityLandingDetected);
#endif	
				return;
			}
			else if(PredictionHits.bHasBlockingHit && PredictionHits.FirstBlockHit.Component.HasTag(n"Walkable") && MoveComp.HorizontalVelocity.Size() > AirMotionComp.Settings.HighspeedLandingHorizontalThreshhold)
			{
				if (CurrTimeStep <= TIME_HIGHSPEEDLANDING)
				{
					//If we are currently tracing for landing and we had a valid and "Walkable" blocking hit
					if(PredictedHitAtTime == 0)
					{
						//If this is our first hit since finding valid hits then save our time of hit
						PredictedHitAtTime = Time::GameTimeSeconds;
						AirMotionComp.AnimData.bHighVelocityLandingDetected = true;
						FHighSpeedLandingDetectedParams Params;
						Params.TimeUntilDetectedLanding = CurrTimeStep;
						UPlayerCoreMovementEffectHandler::Trigger_Landing_HighSpeed_Detected(Player, Params);
					}
				}
				else
				{
					//We had a blocking hit after the highspeedlanding threshhold was passed
					AirMotionComp.AirMotionData.CurrentPredictedDiveHit = FHitResult();
					AirMotionComp.AirMotionData.bDiveDetected = false;
				}
#if !RELEASE
				Log.HitResults("Blocked Walkable Trace: " + i, PredictionHits.FirstBlockHit, PredictionTrace.Shape, PredictionTrace.ShapeWorldOffset);
				Log.Value("HighSpeedLanding Detected", AirMotionComp.AnimData.bHighVelocityLandingDetected);
#endif	
				return;
			}
			else if (!Player.IsCapabilityTagBlocked(PlayerMovementTags::ApexDive))
			{
				//If we got this far and had a blocking hit then break out
				//We are outside of the time frame for HighSpeed landing and we are about to collide with something solid
				if(PredictionHits.HasBlockHits())
					break;
				
				//If we had no overlaps then continue to the next Iteration
				if (!PredictionHits.HasOverlapHits())
					continue;

				//If we already have a valid hit for a swim volume then just return
				if(PredictedHitAtTime != 0 && AirMotionComp.AirMotionData.CurrentPredictedDiveHit.Actor != nullptr)
					return;

				for (auto Hit : PredictionHits.OverlapHits)
				{
					//If we dont have a previous hit then cycle through our overlapped hits and check if we hit a Swim volume
					ASwimmingVolume SwimVolume = Cast<ASwimmingVolume>(Hit.Actor);

					if(SwimVolume != nullptr)
					{
						UPlayerSwimmingComponent SwimComp = UPlayerSwimmingComponent::Get(Player);
						SwimComp.SetState(EPlayerSwimmingState::ApexDive);

						if(PredictedHitAtTime == 0)
						{
							//If we dont have a previous hit then store our time
							PredictedHitAtTime = Time::GameTimeSeconds;
						}
						
						AirMotionComp.AirMotionData.CurrentPredictedDiveHit = Hit;
						AirMotionComp.AirMotionData.bDiveDetected = true;
						return;
					}
				}
			}
		}

		//If we hit nothing then just clear out any stored data
		if(PredictedHitAtTime > 0)
			PredictedHitAtTime = 0;

		AirMotionComp.AnimData.bHighVelocityLandingDetected = false;
		AirMotionComp.AirMotionData.bDiveDetected = false;

#if !RELEASE
		Log.Value("HighSpeedLanding Detected", AirMotionComp.AnimData.bHighVelocityLandingDetected);
#endif	

		return;
	}
};