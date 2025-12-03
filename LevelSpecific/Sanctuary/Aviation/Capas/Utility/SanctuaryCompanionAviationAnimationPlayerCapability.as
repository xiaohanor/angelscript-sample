class USanctuaryCompanionAviationAnimationPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryCompanionAviationPlayerComponent AviationComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AviationComp.MHRidingAnimation == nullptr)
			return false;
		if (!AviationComp.GetIsAviationActive())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.PlayBlendSpace(
			AviationComp.MHRidingAnimation,
			0.2,
			EHazeBlendType::BlendType_Inertialization);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopBlendSpace();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.SetBlendSpaceValues(0.0, 0.0);
	}
};