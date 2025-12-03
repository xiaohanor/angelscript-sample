asset SanctuaryBossPlayerSplineRunSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USanctuaryBossSplineRunEssencePlayerCapability);
	Capabilities.Add(USanctuaryCompanionAviationPhase2DisableDeathCapability);
}

class USanctuaryBossSplineRunEssencePlayerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	UInfuseEssencePlayerComponent LingeringEssenceComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LingeringEssenceComp = UInfuseEssencePlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (LingeringEssenceComp != nullptr)
			LingeringEssenceComp.RemoveFloatyOrbs();
	}
};