class UMedallionPlayerMergeHighfiveAllowstartCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerComponent MedallionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (HighfiveComp.IsHighfiveJumping())
			return false;
		if (MedallionComp.IsMedallionCoopFlying())
			return false;
		if (HighfiveComp.bAllowHighfiveJumpStart)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HighfiveComp.bAllowHighfiveJumpStart = true;
	}
};