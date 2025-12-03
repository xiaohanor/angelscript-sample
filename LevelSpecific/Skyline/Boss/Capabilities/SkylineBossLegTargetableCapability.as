class USkylineBossLegTargetableCapability : USkylineBossChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Boss.IsStateActive(ESkylineBossState::Combat))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Boss.IsStateActive(ESkylineBossState::Combat))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto LegComp : Boss.LegComponents)
			LegComp.Leg.WeaponTargetableComp.Enable(LegComp.Leg);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (auto LegComp : Boss.LegComponents)
			LegComp.Leg.WeaponTargetableComp.Disable(LegComp.Leg);
	}
}