class USanctuaryCompanionAviationEnableMegaCompanionPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::MegaCompanion);
	default DebugCategory = AviationCapabilityTags::Aviation;
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryCompanionMegaCompanionPlayerComponent PlayerComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComponent = USanctuaryCompanionMegaCompanionPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};