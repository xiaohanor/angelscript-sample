struct FMedallionPlayerSidescrollerDeactivationParams
{
	bool bNatural = false;
}

class UMedallionPlayerSidescrollerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(MedallionTags::MedallionSidescrollerTag);

	default TickGroup = EHazeTickGroup::Gameplay;
	UMedallionPlayerComponent MedallionComp;
	UMedallionPlayerMergeHighfiveJumpComponent HighfiveComp;
	UMedallionPlayerReferencesComponent RefsComp;

	bool bManualActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Owner);
		HighfiveComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(Owner);
		RefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RefsComp.Refs == nullptr)
			return false;
		if (MedallionComp.IsMedallionCoopFlying())
			return false;
		if (HighfiveComp.IsHighfiveJumping())
			return false;
		if (HighfiveComp.IsInHighfiveFail())
			return false;
		if (HighfiveComp.bHighfiveResolveTriggered && !HighfiveComp.bHighfiveSuccess)
			return false;
		if (RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMedallionPlayerSidescrollerDeactivationParams& Params) const
	{
		if (MedallionComp.IsMedallionCoopFlying() || HighfiveComp.IsHighfiveJumping() || RefsComp.Refs.HydraAttackManager.Phase > EMedallionPhase::GloryKill3)
		{
			Params.bNatural = true;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (RefsComp.Refs.SideScrollerSplineLocker != nullptr)
			Player.LockMovementToSpline(RefsComp.Refs.SideScrollerSplineLocker, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMedallionPlayerSidescrollerDeactivationParams Params)
	{
		if (RefsComp.Refs.SideScrollerSplineLocker != nullptr)
			Player.UnlockMovementFromSpline(this);
	}
};