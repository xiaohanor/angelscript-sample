class UFallSandFishPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AVortexSandFish SandFish;
	UFallSandFishPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UFallSandFishPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Fall)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Fall)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SandFish = VortexSandFish::GetVortexSandFish();

		USceneComponent AttachComponent = Player.Player == EHazePlayer::Mio ? SandFish.MioFallLocation : SandFish.ZoeFallLocation;
		Player.AttachToComponent(AttachComponent, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DetachFromActor();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
	}
};