class USkylineBallBossChaseSplineCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);
	AHazePlayerCharacter Zoe;
	AHazePlayerCharacter Mio;

	FHazeAcceleratedFloat AccSpeed;
	FHazeAcceleratedFloat AccDuration;
	float SplineDistance;

	FHazeAcceleratedQuat AcceleratedJitterChaseOffsetRotation;
	FQuat JitterOffsetTarget;
	float JitterRetargetCooldown = 1.0;
	float TimeSinceChangeSpline = 0.0;

	float CachedZoeDistance = 0.0;
	float CachedMioDistance = 0.0;
	bool bWasAutoTargeting = false;

	AHazePlayerCharacter LastTargetPlayer;

	float ChaseLaserTrailerStartTimestamp = 0.0;
	FQuat ChaseLaserTrailerStartRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Zoe = Game::Zoe;
		Mio = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallBoss.GetPhase() != ESkylineBallBossPhase::Chase)
			return false;

		if (!BallBoss.HasChaseSpline())
			return false;

		if (DeactiveDuration < Settings.ChaseStartWaitElevatorTime && !BallBoss.bChaseSnapToBehindPlayers)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BallBoss.HasChaseSpline())
			return true;

		if (BallBoss.GetPhase() != ESkylineBallBossPhase::Chase) //  && BallBoss.GetPhase() != ESkylineBallBossPhase::PostChaseElevator
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BallBoss.ResetTarget();
		SplineDistance = 0.0;
		AccDuration.SnapTo(2.5);
		BallBoss.OnChaseLaserSplineChanged.AddUFunction(this, n"OnLaserSplineChanged");
		TimeSinceChangeSpline = 3.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.OnChaseLaserSplineChanged.Unbind(this, n"OnLaserSplineChanged");
	}

	UFUNCTION()
	void OnLaserSplineChanged()
	{
		SplineDistance = 0.0;
		if (ActiveDuration > 3.0)
			TimeSinceChangeSpline = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Zoe.IsPlayerDead() && Mio.IsPlayerDead())
			return;
		ASkylineBallBossChaseSpline CurrentSpline = BallBoss.GetCurrentChaseSpline();
		if (CurrentSpline == nullptr)
			return;

		if (SkylineBallBossDevToggles::DrawChaseSpline.IsEnabled())
		{
			CurrentSpline.Spline.DrawDebug();
			FLinearColor Color = BallBoss.EventSplineID.IsNone() ? ColorDebug::Yellow : ColorDebug::Magenta;
			Debug::DrawDebugString(BallBoss.ActorLocation, "" + CurrentSpline.GetName(), Color);
		}

		CachedZoeDistance = CurrentSpline.Spline.GetClosestSplineDistanceToWorldLocation(Zoe.ActorLocation);
		float ToZoeDistance = CachedZoeDistance - SplineDistance;
		if (Zoe.IsPlayerDead())
			ToZoeDistance = 9999999999.0;
		CachedMioDistance = CurrentSpline.Spline.GetClosestSplineDistanceToWorldLocation(Mio.ActorLocation);
		float ToMioDistance = CachedMioDistance - SplineDistance;
		if (Mio.IsPlayerDead())
			ToMioDistance = 9999999999.0;

		BallBoss.BigLaserActor.ChaseTargetPlayer = ToMioDistance < ToZoeDistance ? Mio : Zoe;

#if EDITOR
		TEMPORAL_LOG(BallBoss).Value("Mio Dist", CachedMioDistance);
		TEMPORAL_LOG(BallBoss).Value("Zoe Dist", CachedZoeDistance);
		FVector ClosestMioLocation = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(CachedMioDistance);
		FVector ClosestZoeLocation = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(CachedZoeDistance);
		TEMPORAL_LOG(BallBoss).Sphere("Mio Closest", ClosestMioLocation, 20.0, ColorDebug::Ruby);
		TEMPORAL_LOG(BallBoss).Sphere("Zoe Closest", ClosestZoeLocation, 20.0, ColorDebug::Leaf);
#endif

		float TargetSpeed = GetTargetSpeed(ToZoeDistance, ToMioDistance, CurrentSpline.OverrideLaserSpeed);
		bool bAutoKillPlayer = CurrentSpline.bAutoKillPlayer && (ToZoeDistance < KINDA_SMALL_NUMBER || ToMioDistance < KINDA_SMALL_NUMBER);
		if (bAutoKillPlayer)
			TargetSpeed = 0.0;
		AccSpeed.AccelerateTo(TargetSpeed, Settings.ChaseLaserSpeedAccDuration, DeltaTime);
		TEMPORAL_LOG(BallBoss).Value("Speed", AccSpeed.Value);

		if (!bAutoKillPlayer)
		{
			float LeastDistance = SplineDistance + AccSpeed.Value * DeltaTime;
			if (LeastDistance >= CurrentSpline.Spline.SplineLength)
			{
				if (CurrentSpline.bAutoProceedToNext)
				{
					SplineDistance = CurrentSpline.Spline.SplineLength;
					UpdateTriggerSplineEvents(CurrentSpline); // might be some events here hehe
					BallBoss.ProceedToNextSpline();
				}
				else
				{
					SplineDistance = BallBoss.ChaseDistanceAfterEventSpline;
					BallBoss.EventSplineID = n"";
					BallBoss.ChaseDistanceAfterEventSpline = 0.0;
				}
				return;
			}

			LeastDistance = Math::Clamp(LeastDistance, 0.0, CurrentSpline.Spline.SplineLength);
			SplineDistance += AccSpeed.Value * DeltaTime;
			if (BallBoss.bChaseSnapToBehindPlayers)
			{
				float SmallestDist = Math::Min(ToZoeDistance, ToMioDistance) - 2000.0;
				SmallestDist = Math::Clamp(SmallestDist, 0.0, CurrentSpline.Spline.SplineLength);
				SplineDistance = SmallestDist;
			}
		}

		FVector TargetLocation = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(SplineDistance);
		FLinearColor DebugTargetColor = ColorDebug::Yellow;
		if (bAutoKillPlayer) // Someone is behind laser! Kill her! pew pew
		{
			if (ToZoeDistance < KINDA_SMALL_NUMBER )
			{
				DebugTargetColor = ColorDebug::Leaf;
				TargetLocation = Zoe.ActorLocation;
				LastTargetPlayer = Zoe;
			}
			if (ToMioDistance < KINDA_SMALL_NUMBER )
			{
				DebugTargetColor = ColorDebug::Ruby;
				TargetLocation = Mio.ActorLocation;
				LastTargetPlayer = Mio;
			}

			// Stay on target if on target!
			if (!bWasAutoTargeting)
			{
				bWasAutoTargeting = true;
				AccDuration.SnapTo(Settings.KillPlayerTargetAccDuration);
			}
			else
				AccDuration.AccelerateTo(Settings.NormalTargetAccDuration, Settings.KillPlayerAcceleratedDuration, DeltaTime);
		}
		else
		{
			if (LastTargetPlayer != nullptr && LastTargetPlayer.IsPlayerDead())
			{
				LastTargetPlayer = nullptr;
				AccDuration.SnapTo(Settings.KillPlayerTargetAccDuration);
			}
			bWasAutoTargeting = false;
			AccDuration.AccelerateTo(Settings.NormalTargetAccDuration, Settings.NormalAcceleratedDuration, DeltaTime);
		}

		JitterRetargetCooldown -= DeltaTime;
		if (JitterRetargetCooldown < 0.0)
		{
			JitterRetargetCooldown = bAutoKillPlayer ? 0.1 : Math::RandRange(Settings.ChaseRotationJitterCooldownMinMax.X, Settings.ChaseRotationJitterCooldownMinMax.Y);
			// JitterOffsetTarget = PickDirection(bAutoKillPlayer).Quaternion();
		}

		// Rotationing
		BallBoss.AcceleratedTargetVector.AccelerateTo(TargetLocation, AccDuration.Value, DeltaTime);
		if (BallBoss.bChaseSnapToBehindPlayers)
			BallBoss.AcceleratedTargetVector.SnapTo(TargetLocation);

		if (SkylineBallBossDevToggles::DrawRotationTarget.IsEnabled())
		{
			CurrentSpline.Spline.DrawDebug();
			Debug::DrawDebugString(TargetLocation, "Dur " + AccDuration.Value, ColorDebug::Magenta, Scale = 3.0);
			Debug::DrawDebugString(TargetLocation, "Rot Target loc", ColorDebug::Yellow);
			Debug::DrawDebugSphere(TargetLocation, 50.0, 12, DebugTargetColor, 4.0, 0.0, true);
		}

		FQuat BallBossRotation = (BallBoss.AcceleratedTargetVector.Value - BallBoss.ActorLocation).GetSafeNormal().Rotation().Quaternion();
		AcceleratedJitterChaseOffsetRotation.SpringTo(JitterOffsetTarget, 400.0, 0.5, DeltaTime);
		// Debug::DrawDebugCoordinateSystem(BallBoss.ActorLocation, AcceleratedJitterChaseOffsetRotation.Value.Rotator(), 5000.0, 10.0, 0.0, true);
		FQuat Combined = BallBossRotation.RotateVector(AcceleratedJitterChaseOffsetRotation.Value.ForwardVector).ToOrientationQuat();

		TimeSinceChangeSpline += DeltaTime;
		float ChangeSplineAlpha = Math::Clamp(TimeSinceChangeSpline / 3.0, 0.0, 1.0);
		float RotationDuration = Math::Lerp(3.0, 0.01, ChangeSplineAlpha);

		if (BallBoss.bIsInChaseTrailerLaser) // super special case hehe
		{
			if (ChaseLaserTrailerStartTimestamp < KINDA_SMALL_NUMBER)
			{
				ChaseLaserTrailerStartTimestamp = Time::GameTimeSeconds;
				ChaseLaserTrailerStartRot = BallBoss.AcceleratedTargetRotation.Value;
			}

			FVector TowardsCamera = BallBoss.TrailerFakeoutCamera.ActorLocation - BallBoss.ActorLocation;

			const float EasingDuration = 0.5;
			const float TimeValue = Time::GameTimeSeconds - ChaseLaserTrailerStartTimestamp;
			const float Alpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, EasingDuration), FVector2D(0.0, 1.0), TimeValue);
			const float CurrentSlerpValue = Math::EaseIn(0.0, 1.0, Alpha, 2.0);
			FQuat DestinationRot = FQuat::MakeFromXZ(TowardsCamera.GetSafeNormal(), FVector::UpVector);
			FQuat NewRot = FQuat::Slerp(ChaseLaserTrailerStartRot, DestinationRot, CurrentSlerpValue);
			BallBoss.AcceleratedTargetRotation.SnapTo(NewRot);
		}
		else
			BallBoss.AcceleratedTargetRotation.AccelerateTo(Combined, RotationDuration, DeltaTime);

		BallBoss.SetActorRotation(BallBoss.AcceleratedTargetRotation.Value);
		BallBoss.bChaseSnapToBehindPlayers = false;

		UpdateTriggerSplineEvents(CurrentSpline);

		if (BallBoss.bIsInChaseTrailerLaser) // super special case hehe
		{
			const float WhiteDiscDistanceInFrontOfCamera = 22;
			const float Distance = (BallBoss.TrailerFakeoutCamera.ActorLocation - BallBoss.BigLaserActor.ActorLocation).Size();
			BallBoss.BigLaserActor.TrailerWhiteOut.SetRelativeLocation(FVector(0.0, 0.0, Distance - WhiteDiscDistanceInFrontOfCamera));

			BallBoss.BigLaserActor.TrailerWhiteOut.SetHiddenInGame(false);
			BallBoss.BigLaserActor.TrailerWhiteOut.SetVisibility(true);
		}
	}

	float GetTargetSpeed(float ToZoeDist, float ToMioDist, float OverrideSpeed)
	{
		if (OverrideSpeed > KINDA_SMALL_NUMBER)
			return OverrideSpeed; 

		float ClosestPlayerDistance = Math::Min(ToZoeDist, ToMioDist) - Settings.ChaseLaserPlayerAcceptedDistance;
		float PlayerSpeedUpRange = Settings.ChaseLaserPlayerPlayerMaxDistance - Settings.ChaseLaserPlayerAcceptedDistance;
		float PlayerFarAlpha = Math::Clamp(ClosestPlayerDistance / PlayerSpeedUpRange, 0.0, 1.0);

		TEMPORAL_LOG(BallBoss).Value("Max Speed Alpha", PlayerFarAlpha);

		return Math::Lerp(Settings.ChaseLaserMinimumSpeed, Settings.ChaseLaserMaxSpeed, PlayerFarAlpha);
	}

	void UpdateTriggerSplineEvents(ASkylineBallBossChaseSpline CurrentSpline)
	{
		if (!HasControl())
			return;
		if (!BallBoss.OnSplineChaseEvent.IsBound())
			return;

		float BallBossCurrentDistance = SplineDistance;
		float MostDistance = Math::Max(Math::Max(CachedZoeDistance, CachedMioDistance), BallBossCurrentDistance);
		for (int i = CurrentSpline.EventComponents.Num() -1; i >= 0; --i)
		{
			USkylineBallBossChaseSplineEventComponent EventComp = CurrentSpline.EventComponents[i];
			if (SkylineBallBossDevToggles::DrawChaseEvents.IsEnabled())
			{
				FVector EventLocation = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(EventComp.DistanceAlongSpline);
				FLinearColor SphereColor = EventComp.GetDebugColor();
				if (EventComp.TriggeredBy == ESkylineBallBossChaseEventTriggerType::OnlyFirstPlayer && (EventComp.bMioPassed || EventComp.bZoePassed))
					SphereColor = ColorDebug::Pumpkin;
				if (EventComp.TriggeredBy == ESkylineBallBossChaseEventTriggerType::BallBoss && EventComp.bBallPassed)
					SphereColor = ColorDebug::Ultramarine;
				Debug::DrawDebugSphere(EventLocation, 150.0, 12, SphereColor);
				Debug::DrawDebugString(EventLocation, "" + EventComp.EventType, FLinearColor::White, 0.0, 2.0);
				if (!EventComp.EventData.Text.IsNone())
					Debug::DrawDebugString(EventLocation, "\n\n\n" + EventComp.EventData.Text, FLinearColor::White, 0.0, 1.5);
			}

			// Cull some checks
			if (EventComp.bMioPassed && EventComp.bZoePassed && EventComp.bBallPassed)
				continue;
			if (EventComp.DistanceAlongSpline > MostDistance + KINDA_SMALL_NUMBER)
				continue;

			bool bZoeDistancePassed = !Zoe.IsPlayerDead() && !EventComp.bZoePassed && EventComp.DistanceAlongSpline <= CachedZoeDistance + KINDA_SMALL_NUMBER;
			bool bMioDistancePassed = !Mio.IsPlayerDead() && !EventComp.bMioPassed && EventComp.DistanceAlongSpline <= CachedMioDistance + KINDA_SMALL_NUMBER;
			bool bTriggerBall = !EventComp.bBallPassed && EventComp.DistanceAlongSpline <= BallBossCurrentDistance + KINDA_SMALL_NUMBER;

			if (EventComp.TriggeredBy == ESkylineBallBossChaseEventTriggerType::BallBoss)
			{
				if (bTriggerBall)
					CrumbSplineEvent(EventComp.EventType, EventComp.EventData);
			}
			else // Triggered by player(s)
			{
				bool bZoePassed = EventComp.bZoePassed || Zoe.IsPlayerDead();
				bool bMioPassed = EventComp.bMioPassed || Mio.IsPlayerDead();
				bool bSingleWasTriggered = EventComp.bMioPassed || EventComp.bZoePassed;
				bool bSingleShouldTrigger = bZoeDistancePassed || bMioDistancePassed;
				bool bRequireBothShouldTrigger = bSingleShouldTrigger && (bZoePassed || bMioPassed);

				if (!bSingleWasTriggered && bSingleShouldTrigger && EventComp.TriggeredBy == ESkylineBallBossChaseEventTriggerType::OnlyFirstPlayer)
					CrumbSplineEvent(EventComp.EventType, EventComp.EventData);
				if (!EventComp.bMioPassed && bMioDistancePassed && (EventComp.TriggeredBy == ESkylineBallBossChaseEventTriggerType::ForBothPlayers || EventComp.TriggeredBy == ESkylineBallBossChaseEventTriggerType::OnlyMio))
					CrumbSplineEvent(EventComp.EventType, EventComp.EventData);
				if (!EventComp.bZoePassed && bZoeDistancePassed && (EventComp.TriggeredBy == ESkylineBallBossChaseEventTriggerType::ForBothPlayers || EventComp.TriggeredBy == ESkylineBallBossChaseEventTriggerType::OnlyZoe))
					CrumbSplineEvent(EventComp.EventType, EventComp.EventData);
				if (bRequireBothShouldTrigger && EventComp.TriggeredBy == ESkylineBallBossChaseEventTriggerType::RequireBothPlayers)
					CrumbSplineEvent(EventComp.EventType, EventComp.EventData);
			}

			CurrentSpline.EventComponents[i].bZoePassed = CurrentSpline.EventComponents[i].bZoePassed || bZoeDistancePassed;
			CurrentSpline.EventComponents[i].bMioPassed = CurrentSpline.EventComponents[i].bMioPassed || bMioDistancePassed;
			CurrentSpline.EventComponents[i].bBallPassed = CurrentSpline.EventComponents[i].bBallPassed || bTriggerBall;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSplineEvent(ESkylineBallBossChaseEventType Type, FSkylineBallBossChaseSplineEventData Data)
	{
		BallBoss.OnSplineChaseEvent.Broadcast(Type, Data);
	}

	private FRotator PickDirection(bool bSmallJitter) const
	{
		float RandomAngle = Math::RandRange(0.0, 360.0);
		FVector RandomUnitVectorOnYZPlane = Math::RotatorFromAxisAndAngle(FVector::ForwardVector, RandomAngle).UpVector;
		const float JitterAngle = bSmallJitter ? Settings.ChaseRotationJitterHitPlayerAngle : Settings.ChaseRotationJitterAngle;
		float RandomOffsetAngle = Math::RandBool() ? -JitterAngle : JitterAngle;
		FVector RandomOffet = Math::RotatorFromAxisAndAngle(RandomUnitVectorOnYZPlane, RandomOffsetAngle).ForwardVector;
		return FRotator::MakeFromXZ(RandomOffet, FVector::UpVector);
	}
}