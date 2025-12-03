class UMedallionPlayerBlockContextualsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionTag);
	default CapabilityTags.Add(MedallionTags::MedallionCoopFlying);

	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HighfiveComp.IsHighfiveJumping())
			return true;
		if (MedallionComp.IsMedallionCoopFlying())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HighfiveComp.IsHighfiveJumping())
			return false;
		if (MedallionComp.IsMedallionCoopFlying())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(PlayerMovementTags::ContextualMovement, this);
		Player.BlockCapabilities(PlayerMovementTags::Swing, this);
		Player.BlockCapabilities(PlayerMovementTags::Grapple, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::ContextualMovement, this);
		Player.UnblockCapabilities(PlayerMovementTags::Swing, this);
		Player.UnblockCapabilities(PlayerMovementTags::Grapple, this);
	}
};
