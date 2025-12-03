class ASkylineBallBossChaseCameraFocusActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	ASkylineBallBoss BallBoss = nullptr;

	UPROPERTY(EditAnywhere)

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;
	FHazeAcceleratedVector AccTargetLocation;
	
	float ActiveDuration = 0.0;
	ASplineActor LastSpline = nullptr;
	bool bFirstFrame = true;
	float TimerUseSmoothInterpolation = 1000.0;
	bool bIsInFakeout = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Zoe = Game::Zoe;
		Mio = Game::Mio;

		FVector BetweenZoeMio = Zoe.ActorLocation + (Mio.ActorLocation - Zoe.ActorLocation) * 0.5;
		AccTargetLocation.SnapTo(BetweenZoeMio);
		SetActorLocation(AccTargetLocation.Value);
		BallBoss.OnSplineChaseEvent.AddUFunction(this, n"SplineEvent");

		SkylineBallBossDevToggles::IsTrailer.MakeVisible();
	}

	UFUNCTION()
	private void SplineEvent(ESkylineBallBossChaseEventType EventType,
	                         FSkylineBallBossChaseSplineEventData EventData)
	{
		if (EventData.Text == n"TimeDilate")
		{
			FTimeDilationEffect Effect;
			Effect.TimeDilation = 0.5;
			Effect.BlendInDurationInRealTime = 0.5;
			Effect.BlendOutDurationInRealTime = 2.0;
			TimeDilation::StartWorldTimeDilationEffect(Effect, this);
			Timer::SetTimer(this, n"ClearTimeDilation", 1.0);
			Timer::SetTimer(this, n"ClearCamera", 2.5);
		}
		if (EventData.Text == n"FakeoutStart")
		{
			bIsInFakeout = true;
			TimerUseSmoothInterpolation = 0.0;
			if (BallBoss.FakeoutCameraSettings != nullptr)
			{
				Mio.ActivateCamera(BallBoss.FakeOutCamera, 4, this, EHazeCameraPriority::VeryHigh);
				//Mio.ApplyCameraSettings(BallBoss.FakeoutCameraSettings, 2.0, this, EHazeCameraPriority::VeryHigh);
				//Zoe.ApplyCameraSettings(BallBoss.FakeoutCameraSettings, 2.0, this, EHazeCameraPriority::VeryHigh);
			}
		}
		if (EventData.Text == n"FakeoutEnd")
		{
			if (SkylineBallBossDevToggles::IsTrailer.IsEnabled() || BallBoss.bTrailerProgressPoint)
			{
				Mio.ActivateCamera(BallBoss.TrailerFakeoutCamera, 1.0, this, EHazeCameraPriority::Cutscene);
				BallBoss.bIsInChaseTrailerLaser = true;
			}
			TimerUseSmoothInterpolation = 0.0;
			bIsInFakeout = false;
		}
	}

	UFUNCTION()
	private void ClearCamera()
	{
			if (BallBoss.FakeoutCameraSettings != nullptr)
			{
				Mio.DeactivateCameraByInstigator(this, 3.0);
				//Mio.ClearCameraSettingsByInstigator(this);
				//Zoe.ClearCameraSettingsByInstigator(this);
			}
	}

	UFUNCTION()
	private void ClearTimeDilation()
	{
		TimeDilation::StopWorldTimeDilationEffect(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (BallBoss.GetPhase() >= ESkylineBallBossPhase::PostChaseElevator)
		{
			SetActorTickEnabled(false);
			return;
		}

		ASplineActor CurrentSpline = BallBoss.GetCurrentChaseSpline(false);
		// if (!ensure(CurrentSpline != nullptr, "No spline for ASkylineBallBossChaseCameraFocusActor to follow!"))
		if (CurrentSpline == nullptr)
		{
			SetActorTickEnabled(false);
			return;
		}

		if (bFirstFrame)
			LastSpline = CurrentSpline;

		if (LastSpline != CurrentSpline)
		{
			LastSpline = CurrentSpline;
		}

		if (BallBoss.bChaseStarted)
		{
			ActiveDuration += DeltaSeconds;
			TimerUseSmoothInterpolation += DeltaSeconds;
		}

		if (Mio.IsPlayerDead() && Zoe.IsPlayerDead())
		{
			if (SkylineBallBossDevToggles::DrawChaseCamera.IsEnabled())
			{
				Debug::DrawDebugString(ActorLocation, "Both players dead", ColorDebug::Ruby);
				Debug::DrawDebugSphere(ActorLocation, 50.0, 12.0, ColorDebug::Bubblegum, 3.0, 0.0, true);
			}

			return;
		}

		FVector TargetPoint;
		float SplineDistanceFutureOffset;

		FLinearColor DebugColor = ColorDebug::Bubblegum;
		if (bIsInFakeout)
		{
			TargetPoint = BallBoss.AcceleratedTargetVector.Value;
			SplineDistanceFutureOffset = -BallBoss.Settings.SplineDistanceForwardOffsetMax;
			DebugColor = ColorDebug::Yellow;
		}
		else if (Mio.IsPlayerDead() || Mio.IsPlayerRespawning())
		{
			TimerUseSmoothInterpolation = -1000.0;
			TargetPoint = Zoe.ActorLocation;
			SplineDistanceFutureOffset = BallBoss.Settings.SplineDistanceForwardOffsetMax;
			DebugColor = ColorDebug::Leaf;
		}
		else if (Zoe.IsPlayerDead() || Zoe.IsPlayerRespawning())
		{
			TimerUseSmoothInterpolation = -1000.0;
			TargetPoint = Mio.ActorLocation;
			SplineDistanceFutureOffset = BallBoss.Settings.SplineDistanceForwardOffsetMax;
			DebugColor = ColorDebug::Ruby;
		}
		else
		{
			FVector DiffBetweenZoeMio = Mio.ActorLocation - Zoe.ActorLocation;
			float OffsetAlpha = Math::Clamp(DiffBetweenZoeMio.Size() / BallBoss.Settings.MaxAllowedDistanceBetweenPlayers, 0.0, 1.0);
			if (BallBoss.GetPhase() == ESkylineBallBossPhase::PostChaseElevator)
				OffsetAlpha = 0.0;
			SplineDistanceFutureOffset = Math::Lerp(BallBoss.Settings.SplineDistanceForwardOffsetMax, 0.0, OffsetAlpha);
			float FakeActiveDuration = Math::Clamp(ActiveDuration - BallBoss.Settings.ChaseStartWaitElevatorTime, 0.0, 999999.0);
			float TimeAlpha = Math::Saturate(FakeActiveDuration / BallBoss.Settings.CamStartSofterInterpolateDuration);
			SplineDistanceFutureOffset = Math::Lerp(0.0, SplineDistanceFutureOffset, TimeAlpha);
			TargetPoint = Zoe.ActorLocation + DiffBetweenZoeMio * 0.5;
			if (SkylineBallBossDevToggles::DrawChaseCamera.IsEnabled())
				Debug::DrawDebugLine(Zoe.ActorLocation, Mio.ActorLocation, DebugColor, 1.0, 0.0, true);
		}

		float Distance = CurrentSpline.Spline.GetClosestSplineDistanceToWorldLocation(TargetPoint);
		Distance = Math::Clamp(Distance + SplineDistanceFutureOffset, 0.0, CurrentSpline.Spline.SplineLength);
		FVector NewTargetPos = CurrentSpline.Spline.GetWorldLocationAtSplineDistance(Distance);
		FVector DiffToTarget = NewTargetPos - TargetPoint;
		DiffToTarget.Z = Math::Clamp(DiffToTarget.Z, -BallBoss.Settings.ChaseCameraMaxVerticalOffset, BallBoss.Settings.ChaseCameraMaxVerticalOffset);
		NewTargetPos = TargetPoint + DiffToTarget;

		float DiedAlpha = Math::Saturate(TimerUseSmoothInterpolation / BallBoss.Settings.CamStartSofterInterpolateDuration);
		float Duration = Math::Lerp(BallBoss.Settings.CamStartSofterInterpolateDuration, BallBoss.Settings.CamNormalInterpolateDuration, DiedAlpha);

		if (bFirstFrame)
			AccTargetLocation.SnapTo(NewTargetPos);
		else
			AccTargetLocation.AccelerateTo(NewTargetPos, Duration, DeltaSeconds);

		if (SkylineBallBossDevToggles::DrawChaseCamera.IsEnabled())
		{
			CurrentSpline.Spline.DrawDebug();
			Debug::DrawDebugString(TargetPoint, "Between Mio & Zoe");
			Debug::DrawDebugSphere(TargetPoint, 10.0, 12.0, DebugColor, 3.0, 0.0, true);
			Debug::DrawDebugString(NewTargetPos, "Future target pos", ColorDebug::Purple);
			Debug::DrawDebugSphere(NewTargetPos, 10.0, 12.0, ColorDebug::Purple, 3.0, 0.0, true);
			Debug::DrawDebugString(AccTargetLocation.Value, "\n\nAccelerate to target", ColorDebug::Pumpkin);
			Debug::DrawDebugSphere(AccTargetLocation.Value, 15.0, 12.0, ColorDebug::Pumpkin, 2.0, 0.0, true);
		}

		SetActorLocation(AccTargetLocation.Value);
		bFirstFrame = false;
	}
};