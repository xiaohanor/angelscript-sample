struct FPaddleRaftPaddleActivationParams
{
	bool bIsPaddlingLeftSide = false;
}

class UPaddleRaftPaddleSideControllerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);
	default DebugCategory = SummitRaftDebug::SummitRaft;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default InterruptsCapabilities(n"PaddleRaftPaddleCapability");

	default TickGroup = EHazeTickGroup::Input;

	UPaddleRaftPlayerComponent RaftComp;
	USummitRaftPaddleComponent PaddleComp;
	USummitRaftPlayerStaggerComponent StaggerComp;

	UPaddleRaftSettings RaftSettings;

	float PaddleStartTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RaftComp = UPaddleRaftPlayerComponent::Get(Player);
		PaddleComp = USummitRaftPaddleComponent::Get(Player);
		StaggerComp = USummitRaftPlayerStaggerComponent::Get(Player);
		RaftSettings = UPaddleRaftSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPaddleRaftPaddleActivationParams& Params) const
	{
		if (StaggerComp.StaggerData.IsSet())
			return false;

		if (IsActioning(ActionNames::PaddleRight) && IsActioning(ActionNames::PaddleLeft))
			return false;
		else if (IsActioning(ActionNames::PaddleRight) && PaddleComp.bLastPaddledLeft)
		{
			Params.bIsPaddlingLeftSide = false;
			return true;
		}
		else if (IsActioning(ActionNames::PaddleLeft) && !PaddleComp.bLastPaddledLeft)
		{
			Params.bIsPaddlingLeftSide = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (StaggerComp.StaggerData.IsSet())
			return true;

		if (Time::GetGameTimeSince(PaddleStartTime) > RaftSettings.PaddleSwitchTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPaddleRaftPaddleActivationParams Params)
	{
		Player.BlockCapabilities(SummitRaftTags::BlockedWhileInSideSwitch, this);
		PaddleComp.bLastPaddledLeft = Params.bIsPaddlingLeftSide;
		PaddleStartTime = Time::GameTimeSeconds;
		if (HasControl())
		{
			if (PaddleComp.bLastPaddledLeft)
				Crumb_SwitchPaddleSide(ERaftPaddleAnimationState::LeftSidePaddle);
			else
				Crumb_SwitchPaddleSide(ERaftPaddleAnimationState::RightSidePaddle);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(SummitRaftTags::BlockedWhileInSideSwitch, this);
		PaddleComp.ClearAnimationStateByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			const float RightTriggerAxis = GetAttributeFloat(AttributeNames::PaddleRightAxis);
			const float LeftTriggerAxis = GetAttributeFloat(AttributeNames::PaddleLeftAxis);
			if (PaddleComp.bLastPaddledLeft)
			{
				if (RightTriggerAxis > LeftTriggerAxis)
					Crumb_SwitchPaddleSide(ERaftPaddleAnimationState::RightSidePaddle);
			}
			else
			{
				if (LeftTriggerAxis > RightTriggerAxis)
					Crumb_SwitchPaddleSide(ERaftPaddleAnimationState::LeftSidePaddle);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_SwitchPaddleSide(ERaftPaddleAnimationState NewPaddleState)
	{
		PaddleComp.ClearAnimationStateByInstigator(this);
		PaddleComp.ApplyAnimationState(NewPaddleState, this, EInstigatePriority::High);
		PaddleStartTime = Time::GameTimeSeconds;
		if (NewPaddleState == ERaftPaddleAnimationState::RightSideIdle || NewPaddleState == ERaftPaddleAnimationState::RightSidePaddle)
			PaddleComp.bLastPaddledLeft = false;
		else
			PaddleComp.bLastPaddledLeft = true;
	}
};