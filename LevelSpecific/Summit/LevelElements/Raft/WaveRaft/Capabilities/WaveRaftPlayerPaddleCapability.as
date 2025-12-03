struct FWaveRaftPaddleActivationParams
{
	bool bIsPaddlingLeftSide = false;
	AWaveRaft Raft;
}

class UWaveRaftPlayerPaddleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(SummitRaftTags::Paddle);
	default DebugCategory = SummitRaftDebug::SummitRaft;
	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UWaveRaftPlayerComponent RaftComp;
	AWaveRaft WaveRaft;

	UWaveRaftSettings RaftSettings;
	USummitRaftPaddleComponent PaddleComp;

	float TargetPaddleDuration = 0;

	FHazeRange PaddleMoveWindow = FHazeRange(0.55, 0.85);

	float CoveredDistance = 0;
	bool bOarIsSubmerged = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RaftComp = UWaveRaftPlayerComponent::Get(Player);
		RaftSettings = UWaveRaftSettings::GetSettings(Player);
		PaddleComp = USummitRaftPaddleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWaveRaftPaddleActivationParams& Params) const
	{
		if (RaftComp.WaveRaft == nullptr)
			return false;

		if (IsActioning(ActionNames::PaddleRight))
		{
			Params.bIsPaddlingLeftSide = false;
			Params.Raft = RaftComp.WaveRaft;
			return true;
		}

		if (IsActioning(ActionNames::PaddleLeft))
		{
			Params.bIsPaddlingLeftSide = true;
			Params.Raft = RaftComp.WaveRaft;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < TargetPaddleDuration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FWaveRaftPaddleActivationParams Params)
	{
		CoveredDistance = 0;
		RaftComp.WaveRaft = Params.Raft;
		WaveRaft = Params.Raft;
		bool bPreviousSide = PaddleComp.bLastPaddledLeft;
		PaddleComp.bLastPaddledLeft = Params.bIsPaddlingLeftSide;

		if (Params.bIsPaddlingLeftSide)
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::LeftSidePaddle, this, EInstigatePriority::High);
		else
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::RightSidePaddle, this, EInstigatePriority::High);

		TargetPaddleDuration = WaveRaftAnimation::PaddleAnimationDuration;
		if (bPreviousSide != PaddleComp.bLastPaddledLeft)
		{
			TargetPaddleDuration += WaveRaftAnimation::PaddleSideSwitchAnimationDuration;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PaddleComp.ClearAnimationStateByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float RemainingDuration = TargetPaddleDuration - ActiveDuration;
		float TotalMoveDist = WaveRaft.RaftSettings.YawPerPaddle;

		FVector LineStart = PaddleComp.Paddle.PaddleTop.WorldLocation;
		FVector LineEnd = PaddleComp.Paddle.PaddleBottom.WorldLocation;
		FVector WaterLocation = PaddleComp.Paddle.WaterSampleComp.GetClosestWaterPointToLine(WaveRaft.CurrentWaterSplineActor.Spline, LineStart, LineEnd);

		if (PaddleComp.Paddle.PaddleBottom.WorldLocation.Z < WaterLocation.Z)
		{
			if (!bOarIsSubmerged)
			{
				FWaveRaftPaddleEventParams Params;
				Params.PaddleLocation = WaterLocation;
				UWaveRaftEventHandler::Trigger_OnPaddleEnterWater(WaveRaft, Params);
				bOarIsSubmerged = true;
			}
			FWaveRaftPaddleEventParams Params;
			Params.PaddleLocation = WaterLocation;
			UWaveRaftEventHandler::Trigger_WhilePaddleSubmerged(WaveRaft, Params);
			if (PaddleComp.bLastPaddledLeft)
				Player.SetFrameForceFeedback(0.1, 0, 0.1, 0, 0.5);
			else
				Player.SetFrameForceFeedback(0, 0.1, 0, 0.1, 0.5);
		}
		else
		{
			bOarIsSubmerged = false;
		}

		if (PaddleMoveWindow.IsInRange(RemainingDuration))
		{
			float Alpha = 1 - Math::Saturate(Math::NormalizeToRange(RemainingDuration, PaddleMoveWindow.Max, PaddleMoveWindow.Min));
			float Easing = Math::CircularIn(0, 1, Alpha);
			float NewDistance = Math::Lerp(0, TotalMoveDist, Easing);
			float MoveSpeed = (NewDistance - CoveredDistance) / DeltaTime;
			RaftComp.PlayerPaddleSpeed = MoveSpeed;
			CoveredDistance = NewDistance;
			// Print(f"{Alpha=}, {Easing=}, {CoveredDistance=}", 5);
		}
		else
			RaftComp.PlayerPaddleSpeed = 0;
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_SwitchPaddleSide(bool bSwitchToLeftSide)
	{
		if (bSwitchToLeftSide)
		{
			PaddleComp.ClearAnimationStateByInstigator(this);
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::LeftSidePaddle, this, EInstigatePriority::High);
			PaddleComp.bLastPaddledLeft = true;
		}
		else
		{
			PaddleComp.ClearAnimationStateByInstigator(this);
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::RightSidePaddle, this, EInstigatePriority::High);
			PaddleComp.bLastPaddledLeft = false;
		}
	}
};