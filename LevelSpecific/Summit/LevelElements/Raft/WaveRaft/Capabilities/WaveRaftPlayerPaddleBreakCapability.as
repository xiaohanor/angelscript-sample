enum EWaveRaftPaddleBreakDirection
{
	Left,
	Right,
	LeftIdle,
	RightIdle
}

class UWaveRaftPlayerPaddleBreakCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default DebugCategory = SummitRaftDebug::SummitRaft;
	default TickGroup = EHazeTickGroup::Movement;

	UWaveRaftPlayerComponent RaftComp;
	AWaveRaft WaveRaft;

	UWaveRaftSettings RaftSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RaftComp = UWaveRaftPlayerComponent::Get(Player);
		RaftSettings = UWaveRaftSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// WaveRaft = RaftComp.WaveRaft;

		// if (Player.IsMio())
		// {
		// 	Player.AttachToComponent(WaveRaft.MioAttachPoint);
		// 	RaftComp.BreakState = EWaveRaftPaddleBreakDirection::LeftIdle;
		// 	RaftComp.LastBreakDirection = EWaveRaftPaddleBreakDirection::Left;
		// }
		// else
		// {
		// 	Player.AttachToComponent(WaveRaft.ZoeAttachPoint);
		// 	RaftComp.BreakState = EWaveRaftPaddleBreakDirection::RightIdle;
		// 	RaftComp.LastBreakDirection = EWaveRaftPaddleBreakDirection::Right;
		// }
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(IsActioning(ActionNames::PrimaryLevelAbility))
		// {
		// 	RaftComp.BreakState = EWaveRaftPaddleBreakDirection::Right;
		// 	RaftComp.LastBreakDirection = EWaveRaftPaddleBreakDirection::Right;
		// }
		// else if(IsActioning(ActionNames::SecondaryLevelAbility))
		// {
		// 	RaftComp.BreakState = EWaveRaftPaddleBreakDirection::Left;
		// 	RaftComp.LastBreakDirection = EWaveRaftPaddleBreakDirection::Left;
		// }
		// else
		// {
		// 	if(RaftComp.LastBreakDirection == EWaveRaftPaddleBreakDirection::Left)
		// 		RaftComp.BreakState = EWaveRaftPaddleBreakDirection::LeftIdle;
		// 	if(RaftComp.LastBreakDirection == EWaveRaftPaddleBreakDirection::Right)
		// 		RaftComp.BreakState = EWaveRaftPaddleBreakDirection::RightIdle;

		// }
		// Player.RequestLocomotion(n"WaveRaft", this);
	}
};