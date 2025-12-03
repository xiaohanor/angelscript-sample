class UKiteFlightPlayerBoostCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(KiteTags::KiteFlight);

	default TickGroup = EHazeTickGroup::Gameplay;

	UKiteFlightPlayerComponent KiteFlightComp;
	
	float CurrentDecayDelayDuration = 0.0;
	float CurrentDecayDuration = 0.0;

	bool bRecentlyBoosted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		KiteFlightComp = UKiteFlightPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!KiteFlightComp.bFlightActive)
			return false;

		if (KiteFlightComp.CurrentBoostValue <= 0.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!KiteFlightComp.bFlightActive)
			return true;

		if (KiteFlightComp.CurrentBoostValue <= 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UCameraSettings::GetSettings(Player).FOV.Clear(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = KiteFlightComp.GetSpeedAlpha();
		
		if (KiteFlightComp.bRecentlyBoosted)
		{
			KiteFlightComp.bRecentlyBoosted = false;
			bRecentlyBoosted = true;
			CurrentDecayDelayDuration = 0.0;
		}

		if (bRecentlyBoosted)
		{
			CurrentDecayDuration = 0.0;
			CurrentDecayDelayDuration += DeltaTime;
			if (CurrentDecayDelayDuration >= KiteFlight::GetRubberBandingDecayDelay(Player))
			{
				CurrentDecayDelayDuration = 0.0;
				bRecentlyBoosted = false;
			}
		}
		else
		{
			KiteFlightComp.CurrentBoostValue = Math::Clamp(KiteFlightComp.CurrentBoostValue - (KiteFlight::BoostDecayRate * KiteFlight::GetRubberBandingDecayRate(Player) * DeltaTime), 0.0, KiteFlight::GetMaxSpeedWithRubberbanding(Player));
		}

		float FoV = Math::Lerp(0.0, 15.0, KiteFlightComp.GetSpeedAlpha());
		UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(FoV, this, 0.0, EHazeCameraPriority::High);
	}
}