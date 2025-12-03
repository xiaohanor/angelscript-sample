struct FSkylineBossTargetActivateParams
{
	AHazeActor LookAtTarget;
};

class USkylineBossTargetCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossTarget);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTargetActivateParams& Params) const
	{
		if (DeactiveDuration < 3.0)
			return false;

		// By default, get Mio
		if (Boss.LookAtTarget.IsDefaultValue())
			Params.LookAtTarget = Game::Mio;
		else
		{
			// Switch target
			auto TargetBike = Cast<AGravityBikeFree>(Boss.LookAtTarget.Get());
			if (TargetBike != nullptr)
				Params.LookAtTarget = TargetBike.GetDriver().OtherPlayer;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 6.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossTargetActivateParams Params)
	{
		Boss.SetLookAtTarget(Params.LookAtTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}