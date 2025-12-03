class USandHandActiveCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;	// Replicated through the other capabilities activating

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(SandHand::Tags::SandHand);
	default CapabilityTags.Add(SandHand::Tags::SandHandActiveCapability);

	default TickGroup = EHazeTickGroup::Gameplay;

	USandHandPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USandHandPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!PlayerComp.IsUsingSandHands())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PlayerComp.IsUsingSandHands())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.EnableStrafe(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DisableStrafe(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(SandHand::Feature, this);
	}
};