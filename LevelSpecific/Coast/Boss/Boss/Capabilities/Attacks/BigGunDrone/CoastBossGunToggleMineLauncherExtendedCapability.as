struct FCoastBossGunToggleMineLauncherExtendedParams
{
	bool bExtended;
}

class UCoastBossGunToggleMineLauncherExtendedCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CoastBossTags::CoastBossTag);
	default TickGroup = EHazeTickGroup::Gameplay;

	ACoastBoss Boss;

	FCoastBossGunToggleMineLauncherExtendedParams QueueParameters;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ACoastBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FCoastBossGunToggleMineLauncherExtendedParams Parameters)
	{
		QueueParameters = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(QueueParameters.bExtended)
		{
			Boss.MineLauncher.Extend(this);
			UCoastBossEventHandler::Trigger_OnExtendMineLauncher(Boss);
		}
		else
		{
			Boss.MineLauncher.Retract(this);
			UCoastBossEventHandler::Trigger_OnRetractMineLauncher(Boss);
		}
	}
}