
class UWaveRaftPlayerLeanCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SummitRaftTags::WaveRaft);
	default TickGroup = EHazeTickGroup::LastMovement;
	default DebugCategory = SummitRaftDebug::SummitRaft;

	UWaveRaftPlayerComponent RaftComp;
	AWaveRaft WaveRaft;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RaftComp = UWaveRaftPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RaftComp.WaveRaft == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RaftComp.WaveRaft == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WaveRaft = RaftComp.WaveRaft;

		if (Player.IsMio())
			Player.AttachToComponent(WaveRaft.MioAttachPoint);
		else
			Player.AttachToComponent(WaveRaft.ZoeAttachPoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Update the lean value for the players on the raft

		FVector2D Input;
		if(IsActioning(ActionNames::PrimaryLevelAbility))
			Input = FVector2D(1.0, 0.0);
		else if(IsActioning(ActionNames::SecondaryLevelAbility))
			Input = FVector2D(-1.0, 0.0);
		else
			Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);	
		RaftComp.Input = Input;
		RaftComp.PlayerLean = Math::Lerp(RaftComp.PlayerLean, RaftComp.Input.X, 3.0 * DeltaTime);

		// Animate the players
		Player.RequestLocomotion(n"WaveRaft", this);
	}
};