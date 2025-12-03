
/**
 * Non-player controlled paddle, does no movement
 */
class UPaddleRaftFakePaddleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);

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

	float LastFakeStrokeFinishTime = 0;
	bool bHasBlockedGameplay = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StaggerComp = USummitRaftPlayerStaggerComponent::Get(Player);
		PaddleComp = USummitRaftPaddleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto PlayerRaftComp = UPaddleRaftPlayerComponent::Get(Player);

		if (PlayerRaftComp == nullptr)
			return false;

		if (PlayerRaftComp.PaddleRaft == nullptr)
			return false;

		if (PlayerRaftComp.NumQueuedFakePaddleStrokes <= 0)
			return false;

		if (Time::GetGameTimeSince(LastFakeStrokeFinishTime) < PlayerRaftComp.TimeBetweenFakePaddleStrokes)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= RaftSettings.PaddleTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RaftComp = UPaddleRaftPlayerComponent::Get(Player);
		if (HasControl() && RaftComp.NumQueuedFakePaddleStrokes > 0 && !bHasBlockedGameplay)
		{
			Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
			bHasBlockedGameplay = true;
		}

		RaftSettings = UPaddleRaftSettings::GetSettings(RaftComp.PaddleRaft);
		Raft = RaftComp.PaddleRaft;
		PaddleComp.ClearAnimationStateByInstigator(this);
		Raft.PaddlingPlayers[Player] = true;

		if (PaddleComp.bLastPaddledLeft)
		{
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::LeftSidePaddle, this, EInstigatePriority::High);
			RaftComp.PaddleRaft.PlayerPaddleData[Player].Side = ERaftPaddleSide::Left;
		}
		else
		{
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::RightSidePaddle, this, EInstigatePriority::High);
			RaftComp.PaddleRaft.PlayerPaddleData[Player].Side = ERaftPaddleSide::Right;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Raft.PaddlingPlayers[Player] = false;
		PaddleComp.ClearAnimationStateByInstigator(this);

		RaftComp.PaddleRaft.PlayerPaddleData[Player].RotationSpeed = 0;
		RaftComp.PaddleRaft.PlayerPaddleData[Player].ForwardSpeed = 0;
		RaftComp.PaddleRaft.PlayerPaddleData[Player].Side = ERaftPaddleSide::None;
		LastFakeStrokeFinishTime = Time::GameTimeSeconds;
		RaftComp.NumQueuedFakePaddleStrokes--;
		if (HasControl() && RaftComp.NumQueuedFakePaddleStrokes <= 0 && bHasBlockedGameplay)
		{
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
			bHasBlockedGameplay = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector LineStart = PaddleComp.Paddle.PaddleTop.WorldLocation;
		FVector LineEnd = PaddleComp.Paddle.PaddleBottom.WorldLocation;
		FVector WaterLocation = PaddleComp.Paddle.WaterSampleComp.GetClosestWaterPointToLine(Raft.WaterSplineActor.Spline, LineStart, LineEnd);

		if (PaddleComp.Paddle.PaddleBottom.WorldLocation.Z < WaterLocation.Z)
		{
			if (!bOarIsSubmerged)
			{
				FPaddleOarEventParams Params;
				Params.OarWaterEnterLocation = WaterLocation;
				UPaddleRaftEventHandler::Trigger_OnOarEnterWater(RaftComp.PaddleRaft, Params);
				bOarIsSubmerged = true;
			}

			FPaddleOarEventParams Params;
			Params.OarWaterEnterLocation = WaterLocation;
			UPaddleRaftEventHandler::Trigger_WhileOarSubmerged(RaftComp.PaddleRaft, Params);
		}
		else
		{
			bOarIsSubmerged = false;
		}
	}
};