class URedSpaceAnomalyPlayerSpreadCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	URedSpaceAnomalyPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = URedSpaceAnomalyPlayerComponent::GetOrCreate(Player);
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
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (ARedSpaceAnomaly Anomaly : PlayerComp.GetAnomalies())
		{
			if (Anomaly.Mode == ERedSpaceAnomalyMode::Spread)
			{
				float Dist = Anomaly.GetDistanceTo(Player);
				if (Dist <= Anomaly.AffectDistance)
					Anomaly.Restore();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (ARedSpaceAnomaly Anomaly : PlayerComp.GetAnomalies())
		{
			if (Anomaly.Mode == ERedSpaceAnomalyMode::Spread)
			{
				float Dist = Anomaly.GetDistanceTo(Player);
				if (Dist <= Anomaly.AffectDistance)
				{
					Anomaly.Restore();
				}
				else
				{
					Anomaly.Anomalize();
				}
			}
		}
	}
}