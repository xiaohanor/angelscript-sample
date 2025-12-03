class UDentistBossToolDenturesRidingFocusTargetCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;
	UDentistBossTargetComponent TargetComp;
	UDentistBossSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();
		TargetComp = UDentistBossTargetComponent::Get(Dentist);
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.bActive)
			return false;

		if(Dentures.bIsAttachedToJaw)
			return false;

		if(!Dentures.ControllingPlayer.IsSet())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Dentures.bDestroyed)
			return true;

		if(!Dentures.bActive)
			return true;

		if(Dentures.bIsAttachedToJaw)
			return true;

		if(!Dentures.ControllingPlayer.IsSet())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetComp.Target.Apply(Dentures.ControllingPlayer.Value, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetComp.Target.Clear(this);
	}
};