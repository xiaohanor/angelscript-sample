class UPaddleRaftPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SummitRaftTags::PaddleRaft);
	default TickGroup = EHazeTickGroup::LastMovement;
	default DebugCategory = SummitRaftDebug::SummitRaft;

	UPaddleRaftPlayerComponent RaftComp;
	USummitRaftPaddleComponent PaddleComp;
	APaddleRaft PaddleRaft;

	UPaddleRaftSettings RaftSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RaftComp = UPaddleRaftPlayerComponent::Get(Player);
		PaddleComp = USummitRaftPaddleComponent::Get(Player);

		if (Player.IsMio())
			PaddleComp.bLastPaddledLeft = true;
		else
			PaddleComp.bLastPaddledLeft = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RaftComp.PaddleRaft != nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RaftComp.PaddleRaft == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PaddleRaft = RaftComp.PaddleRaft;
		RaftSettings = UPaddleRaftSettings::GetSettings(PaddleRaft);

		if (Player.IsMio())
			Player.AttachToComponent(PaddleRaft.MioAttachPoint);
		else
			Player.AttachToComponent(PaddleRaft.ZoeAttachPoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DetachRootComponentFromParent();
		PaddleComp.ClearAnimationStateByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PaddleComp.bLastPaddledLeft)
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::LeftSideIdle, this, EInstigatePriority::Low);
		else
			PaddleComp.ApplyAnimationState(ERaftPaddleAnimationState::RightSideIdle, this, EInstigatePriority::Low);

		// Animate the players
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"PaddleRaft", this);
	}
};