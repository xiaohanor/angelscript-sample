
class UAnimationSettingsComponent : UActorComponent
{
	private TInstigated<bool> AllowRelaxAnimDuringOverride;
	default AllowRelaxAnimDuringOverride.DefaultValue = false;

	void ApplyAllowRelaxAnimDuringOverride(bool bAllow, FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		AllowRelaxAnimDuringOverride.Apply(bAllow, Instigator, Priority);
	}

	void ClearAllowRelaxAnimDuringOverride(FInstigator Instigator)
	{
		AllowRelaxAnimDuringOverride.Clear(Instigator);
	}

	bool GetAllowRelaxAnimDuringOverride()
	{
		return AllowRelaxAnimDuringOverride.Get();
	}
}