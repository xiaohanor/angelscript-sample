class UWaveRaftPaddleRotationCapability : UHazeCapability
{
	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default CapabilityTags.Add(SummitRaftTags::BlockedWhileInHitStagger);
	default TickGroup = EHazeTickGroup::Input;
	default DebugCategory = SummitRaftDebug::SummitRaft;

	AWaveRaft WaveRaft;

	UWaveRaftSettings RaftSettings;

	TPerPlayer<USummitRaftPaddleComponent> PaddleComps;
	TPerPlayer<UWaveRaftPlayerComponent> RaftComps;

	UHazeMovementComponent MoveComp;
	FHazeAcceleratedFloat AccFrontHeight;
	FHazeAcceleratedFloat AccBackHeight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaveRaft = Cast<AWaveRaft>(Owner);
		MoveComp = UHazeMovementComponent::Get(WaveRaft);

		RaftSettings = UWaveRaftSettings::GetSettings(WaveRaft);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WaveRaft.SplinePos.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!WaveRaft.SplinePos.IsValid())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto Player : Game::Players)
		{
			PaddleComps[Player] = USummitRaftPaddleComponent::Get(Player);
			RaftComps[Player] = UWaveRaftPlayerComponent::Get(Player);
		}
		AccFrontHeight.SnapTo(WaveRaft.ActorLocation.Z);
		AccBackHeight.SnapTo(WaveRaft.ActorLocation.Z);
		WaveRaft.AccWaveRaftRotation.SnapTo(WaveRaft.ActorRotation);
		// WaveRaft.AccYawSpeed.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bWasFalling = WaveRaft.bIsFalling;
		WaveRaft.bIsFalling = !WaveRaft.HasWaterBellow(150) || RaftSettings.bForceAirborne;
		if (HasControl())
		{
			bool bIsPaddling = false;

			if (bWasFalling && !WaveRaft.bIsFalling)
			{
				AccFrontHeight.SnapTo(WaveRaft.FRWaterSampleComp.WorldLocation.Z);
				AccBackHeight.SnapTo(WaveRaft.BRWaterSampleComp.WorldLocation.Z);
			}

			float CurrentPaddleSpeed = 0;
			if (!WaveRaft.bIsFalling)
			{
				for (auto Player : Game::Players)
				{
					auto AnimationState = PaddleComps[Player].AnimationState.Get();
					if (AnimationState == ERaftPaddleAnimationState::LeftSideIdle || AnimationState == ERaftPaddleAnimationState::RightSideIdle)
						continue;

					if (AnimationState == ERaftPaddleAnimationState::LeftSidePaddle)
						CurrentPaddleSpeed += RaftComps[Player].PlayerPaddleSpeed;
					else if (AnimationState == ERaftPaddleAnimationState::RightSidePaddle)
						CurrentPaddleSpeed -= RaftComps[Player].PlayerPaddleSpeed;

					bIsPaddling = true;
				}
			}

			if (!Math::IsNearlyZero(CurrentPaddleSpeed))
				WaveRaft.AccYawSpeed.AccelerateTo(CurrentPaddleSpeed, RaftSettings.WaveRaftTurnDuration, DeltaTime);
			else
				WaveRaft.AccYawSpeed.AccelerateTo(CurrentPaddleSpeed, RaftSettings.WaveRaftTurnBrakeDuration, DeltaTime);

			TEMPORAL_LOG(this).Value("AccYawSpeed", WaveRaft.AccYawSpeed.Value);
			// check(!bIsPaddling);

			float YawDelta = WaveRaft.AccYawSpeed.Value * DeltaTime;

			if (RaftSettings.bUseAutoSteering)
			{
				auto NewSplinePos = WaveRaft.SplinePos;
				NewSplinePos.Move(1500);
				FRotator ToSplineRotation = FRotator::MakeFromXZ((NewSplinePos.WorldLocation - WaveRaft.ActorLocation).GetSafeNormal2D(), WaveRaft.SplinePos.WorldUpVector);
				ToSplineRotation.Roll = 0;
				ToSplineRotation.Pitch = 0;
				WaveRaft.AccWaveRaftRotation.AccelerateTo(ToSplineRotation, RaftSettings.AutoSteeringDuration, DeltaTime);
			}
			else if (!RaftSettings.bUseAutoSteering && !bIsPaddling)
			{
				float SteeringInterp = RaftSettings.DefaultNoPaddleRotateBackInterpSpeed;
				YawDelta = Math::FInterpTo(YawDelta, 0, DeltaTime, SteeringInterp);
			}

			if (!RaftSettings.bUseAutoSteering)
			{
				FVector FrontLeft = WaveRaft.FLWaterSampleComp.GetWaterLocation(WaveRaft.CurrentWaterSplineActor.Spline);
				FVector FrontRight = WaveRaft.FRWaterSampleComp.GetWaterLocation(WaveRaft.CurrentWaterSplineActor.Spline);
				FVector BackLeft = WaveRaft.BLWaterSampleComp.GetWaterLocation(WaveRaft.CurrentWaterSplineActor.Spline);
				FVector BackRight = WaveRaft.BRWaterSampleComp.GetWaterLocation(WaveRaft.CurrentWaterSplineActor.Spline);

				if (Math::Abs(FrontLeft.Z - BackLeft.Z) > 25)
				{
					FrontLeft.Z = BackLeft.Z;
					FrontRight.Z = FrontRight.Z;
				}

				FVector FrontMiddle = (FrontLeft + FrontRight) * 0.5;
				FVector BackMiddle = (BackLeft + BackRight) * 0.5;

				if (!WaveRaft.bIsFalling)
				{
					AccFrontHeight.AccelerateTo(FrontMiddle.Z, 0.25, DeltaTime);
					AccBackHeight.AccelerateTo(BackMiddle.Z, 0.5, DeltaTime);
				}

				FrontMiddle.Z = AccFrontHeight.Value;
				BackMiddle.Z = AccBackHeight.Value;
				FVector Forward = (FrontMiddle - BackMiddle).GetSafeNormal();
				FVector Right = WaveRaft.ActorRightVector;
				FVector Up = Forward.CrossProduct(Right).GetSafeNormal();

				// abs it so we never have the normal from underneath the water downwards
				Up.Z = Math::Abs(Up.Z);

				FRotator Rotation = WaveRaft.ActorRotation;
				FRotator TargetRotation = WaveRaft.SplinePos.WorldRotation.Rotator();

				// check(!bIsPaddling);
				Rotation = FRotator::MakeFromXZ(Rotation.ForwardVector.ConstrainToPlane(Up), Up);
				Rotation.Yaw = Math::Clamp(Rotation.Yaw + YawDelta, TargetRotation.Yaw - RaftSettings.MaxYawFromSpline, TargetRotation.Yaw + RaftSettings.MaxYawFromSpline);
				Rotation.Roll = 0.0;
				if (!WaveRaft.bIsFalling)
				{
					WaveRaft.AccWaveRaftRotation.AccelerateTo(Rotation, 0.5, DeltaTime);
					WaveRaft.AccWaveRaftRotation.Value.Yaw = Rotation.Yaw;
				}
				else
				{
					Rotation.Pitch = 0;
					WaveRaft.AccWaveRaftRotation.AccelerateTo(Rotation, 1, DeltaTime);
				}
			}
		}
	}
};