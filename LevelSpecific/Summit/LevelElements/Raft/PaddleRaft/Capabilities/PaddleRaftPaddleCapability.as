struct FPaddleRaftPaddlingActivationParams
{
	APaddleRaft PaddleRaft;
}

class UPaddleRaftPaddleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);
	default CapabilityTags.Add(SummitRaftTags::BlockedWhileInSideSwitch);

	default DebugCategory = SummitRaftDebug::SummitRaft;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	APaddleRaft Raft;

	UPaddleRaftPlayerComponent RaftComp;
	USummitRaftPaddleComponent PaddleComp;

	UPaddleRaftSettings RaftSettings;

	bool bOarIsSubmerged = false;

	float PaddleStartTime;
	USummitRaftPlayerStaggerComponent StaggerComp;

	float TargetPaddleDuration = 0;

	FHazeRange PaddleMoveWindow = FHazeRange(0.0, 0.9);

	float CoveredDistance = 0;
	float PreviousRotationDistance = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StaggerComp = USummitRaftPlayerStaggerComponent::Get(Player);
		PaddleComp = USummitRaftPaddleComponent::Get(Player);
		RaftComp = UPaddleRaftPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPaddleRaftPaddlingActivationParams& Params) const
	{
		if (Raft != nullptr && StaggerComp.StaggerData.IsSet())
			return false;

		if (!IsActioning(ActionNames::PaddleRight) && !IsActioning(ActionNames::PaddleLeft))
			return false;

		if (RaftComp.PaddleRaft == nullptr)
			return false;

		Params.PaddleRaft = RaftComp.PaddleRaft;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= RaftSettings.PaddleTime)
			return true;

		if (Raft != nullptr && StaggerComp.StaggerData.IsSet())
			return true;

		if (RaftComp.PaddleRaft == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPaddleRaftPaddlingActivationParams Params)
	{
		CoveredDistance = 0;

		Raft = Params.PaddleRaft;
		RaftSettings = UPaddleRaftSettings::GetSettings(Raft);
		PaddleComp.ClearAnimationStateByInstigator(this);
		Raft.PaddlingPlayers[Player] = true;

		if (PaddleComp.bLastPaddledLeft)
		{
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::LeftSidePaddle, this, EInstigatePriority::High);
			Raft.PlayerPaddleData[Player].Side = ERaftPaddleSide::Left;
		}
		else
		{
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::RightSidePaddle, this, EInstigatePriority::High);
			Raft.PlayerPaddleData[Player].Side = ERaftPaddleSide::Right;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PaddleComp.ClearAnimationStateByInstigator(this);

		if (Raft != nullptr)
		{
			Raft.PaddlingPlayers[Player] = false;
			Raft.PlayerPaddleData[Player].RotationSpeed = 0;
			Raft.PlayerPaddleData[Player].ForwardSpeed = 0;
			Raft.PlayerPaddleData[Player].Side = ERaftPaddleSide::None;
		}

		PaddleComp.ClearAnimationStateByInstigator(this);
		if (PaddleComp.bLastPaddledLeft)
		{
			if (ActiveDuration > 0.4)
			{
				PaddleComp.OnPaddleLeft.Broadcast();
			}
		}
		else
		{
			if (ActiveDuration > 0.4)
			{
				PaddleComp.OnPaddleRight.Broadcast();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TotalMoveDist = RaftSettings.ForwardSpeedAccelerationPerPlayer * RaftSettings.PaddleTime;
		float TotalRotationAmount = RaftSettings.PlayerPaddleRotationSpeed;
		float CurrentMoveSpeed = 0;
		float CurrentRotationSpeed = 0;
		float RemainingDuration = RaftSettings.PaddleTime - ActiveDuration;
		if (PaddleMoveWindow.IsInRange(RemainingDuration))
		{
			float Alpha = 1 - Math::Saturate(Math::NormalizeToRange(RemainingDuration, PaddleMoveWindow.Min, PaddleMoveWindow.Max));
			float Easing = Math::CircularOut(0, 1, Alpha);
			float NewForwardDistance = Math::Lerp(0, TotalMoveDist, Easing);
			float NewRotationDistance = Math::Lerp(0, TotalRotationAmount, Easing);
			CurrentMoveSpeed = (NewForwardDistance - CoveredDistance) / DeltaTime;
			CurrentRotationSpeed = (NewRotationDistance - PreviousRotationDistance) / DeltaTime;

			CoveredDistance = NewForwardDistance;
			PreviousRotationDistance = NewRotationDistance;
			Raft.PlayerPaddleData[Player].TimeLastPaddled = Time::GameTimeSeconds;
		}

		Raft.PlayerPaddleData[Player].RotationSpeed = CurrentRotationSpeed;
		Raft.PlayerPaddleData[Player].ForwardSpeed = CurrentMoveSpeed;

		FVector LineStart = PaddleComp.Paddle.PaddleTop.WorldLocation;
		FVector LineEnd = PaddleComp.Paddle.PaddleBottom.WorldLocation;
		FVector WaterLocation = PaddleComp.Paddle.WaterSampleComp.GetClosestWaterPointToLine(Raft.WaterSplineActor.Spline, LineStart, LineEnd);

		if (PaddleComp.Paddle.PaddleBottom.WorldLocation.Z < WaterLocation.Z)
		{
			if (!bOarIsSubmerged)
			{
				FPaddleOarEventParams Params;
				Params.OarWaterEnterLocation = WaterLocation;
				UPaddleRaftEventHandler::Trigger_OnOarEnterWater(Raft, Params);
				bOarIsSubmerged = true;
			}

			FPaddleOarEventParams Params;
			Params.OarWaterEnterLocation = WaterLocation;
			UPaddleRaftEventHandler::Trigger_WhileOarSubmerged(Raft, Params);

			if (PaddleComp.bLastPaddledLeft)
				Player.SetFrameForceFeedback(0.1, 0, 0.1, 0, 0.5);
			else
				Player.SetFrameForceFeedback(0, 0.1, 0, 0.1, 0.5);
		}
		else
		{
			bOarIsSubmerged = false;
		}
	}
};