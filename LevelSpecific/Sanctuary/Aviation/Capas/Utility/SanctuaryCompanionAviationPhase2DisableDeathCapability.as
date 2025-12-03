
class USanctuaryCompanionAviationPhase2DisableDeathCapability : UHazePlayerCapability
{
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
		if (!HasControl())
			return false;
		
		if (IsInPhase1())
			return false;

		if (!IsGrappleSwinging())
			return false;

		return true;
	}

	bool IsGrappleSwinging() const
	{
		if (Player.IsAnyCapabilityActive(PlayerMovementTags::Swing))
			return true;

		if (Player.IsAnyCapabilityActive(PlayerMovementTags::Grapple))
			return true;

		return false;
	}

	bool IsInPhase1() const
	{
		TListedActors<ASanctuaryBossArenaHydra> Hydras;
		return Hydras.Num() > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsGrappleSwinging())
			return true;
		
		if (ActiveDuration > 5.0) // You're getting some help but not inf time
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"Death", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"Death", this);
	}
};

