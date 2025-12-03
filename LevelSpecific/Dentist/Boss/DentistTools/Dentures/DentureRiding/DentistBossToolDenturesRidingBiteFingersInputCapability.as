class UDentistBossToolDenturesRidingBiteFingersInputCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 60;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolDentures Dentures;

	UDentistBossSettings Settings;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.ControllingPlayer.IsSet())
			return false;

		if(!Dentures.IsBitingHand())
			return false;

		if(ButtonMash::ShouldButtonMashesBeAutomatic(Dentures.ControllingPlayer.Value))
			return true;

		if(ButtonMash::ShouldButtonMashesBeHolds(Dentures.ControllingPlayer.Value)
		&& IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		if(WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.1))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Dentures.bDestroyed)
			return true;

		if(!Dentures.ControllingPlayer.IsSet())
			return true;

		if(!Dentures.IsBitingHand())
			return true;

		if(ButtonMash::ShouldButtonMashesBeHolds(Dentures.ControllingPlayer.Value))
		{
			if(!IsActioning(ActionNames::PrimaryLevelAbility))
				return true;
		}
		else if(!ButtonMash::ShouldButtonMashesBeAutomatic(Dentures.ControllingPlayer.Value)
		&& !ButtonMash::ShouldButtonMashesBeHolds(Dentures.ControllingPlayer.Value))
		{
			if(WasActionStarted(ActionNames::PrimaryLevelAbility))
				return true;
		}

		if(ActiveDuration > DentistBossTimings::DenturesBiteHand)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentures.bBiteInput = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Dentures.bBiteInput = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}	
};