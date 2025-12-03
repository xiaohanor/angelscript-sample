class UMedallionPlayerMergeHighfiveResetCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	UMedallionPlayerGloryKillComponent GloryKillComp;
	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryKillComp = UMedallionPlayerGloryKillComponent::GetOrCreate(Player);
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (!HighfiveComp.bHighfiveResolveTriggered)
			return false;
		if (HighfiveComp.bGameOvering)
			return false;

		// if anyone ded, yes
		if (Player.IsPlayerDead())
			return true;
		if (Player.OtherPlayer.IsPlayerDead())
			return true;

		// we started killing?
		if (GloryKillComp.GloryKillState != EMedallionGloryKillState::None)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HighfiveComp.bAllowFlying = false;
		HighfiveComp.bHighfiveJumpStartTriggered = false;
		HighfiveComp.bHighfiveResolveTriggered = false;
		HighfiveComp.bHighfiveSuccess = false;
		HighfiveComp.HighfiveHoldAlpha = 0.0;
	}
};