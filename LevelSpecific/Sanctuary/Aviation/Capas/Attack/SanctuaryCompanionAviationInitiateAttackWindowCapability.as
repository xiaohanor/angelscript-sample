struct FSanctuaryCompanionAviationInitiateAttackWindowDeactivationParams
{
	bool bNatural = false;
}

class USanctuaryCompanionAviationInitiateAttackWindowCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.HasDestination())
			return false;

		if (!Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return false;

		if (AviationComp.AviationState != EAviationState::InitAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSanctuaryCompanionAviationInitiateAttackWindowDeactivationParams& Params) const
	{
		if (DeactivateChecks())
		{
			Params.bNatural = true;
			return true;
		}

		return false;
	}

	bool DeactivateChecks() const
	{
		if (!AviationComp.HasDestination())
			return true;

		if (!Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return true;

		if (AviationComp.AviationState != EAviationState::InitAttack)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AviationComp.bHasInitiatedAttack = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSanctuaryCompanionAviationInitiateAttackWindowDeactivationParams Params)
	{
		AviationComp.bHasInitiatedAttack = false;
		AviationComp.bCanInitiatingAttackingTarget = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > AviationComp.Settings.InitiateAttackWindowDelay)
			AviationComp.bCanInitiatingAttackingTarget = true;
	}

};