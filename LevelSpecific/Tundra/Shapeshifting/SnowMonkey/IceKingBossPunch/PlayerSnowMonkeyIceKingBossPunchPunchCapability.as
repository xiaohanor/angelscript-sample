class UTundraPlayerSnowMonkeyIceKingBossPunchPunchCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyBossPunch);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyBossPunching);

	UTundraPlayerSnowMonkeyIceKingBossPunchComponent BossPunchComp;
	UTundraPlayerSnowMonkeyIceKingBossPunchSettings Settings;
	ATundraBoss Boss;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Player);
		Settings = UTundraPlayerSnowMonkeyIceKingBossPunchSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BossPunchComp.CanPunch())
			return false;

		if(BossPunchComp.TypeSettings.bAutomaticallyPunchLastPunch && BossPunchComp.AmountOfPunchesPerformed == BossPunchComp.TypeSettings.BossPunchesAmount - 1)
			return true;

		if(BossPunchComp.TypeSettings.bAutomaticallyPunchFirstPunch && BossPunchComp.AmountOfPunchesPerformed == 0)
			return true;

		if(BossPunchComp.TypeSettings.bAutomaticallyPunchSecondPunch && BossPunchComp.AmountOfPunchesPerformed == 1)
			return true;

		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.1))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(HasControl())
			NetStopSlowMotion();
			
		BossPunchComp.AnimData.bPunchingThisFrame = true;
		
		if(TryGetBoss() != nullptr)
			Boss.SetPunchingThisFrame(true, BossPunchComp.Type, BossPunchComp.AmountOfPunchesPerformed);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
		++BossPunchComp.AmountOfPunchesPerformed;
		BossPunchComp.TimeOfLastPunch = Time::GetGameTimeSeconds();
		BossPunchComp.RealTimeOfLastPunch = Time::GetRealTimeSeconds();

		if(BossPunchComp.Type == ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch && BossPunchComp.AmountOfPunchesPerformed == BossPunchComp.TypeSettings.BossPunchesAmount)
		{
			if(TryGetBoss() != nullptr)
				Boss.SetLastFinalPunchThisFrame(true);

			BossPunchComp.AnimData.bShouldPlayLastFinalPunch = true;
		}
	}

	UFUNCTION(NetFunction)
	private void NetStopSlowMotion()
	{
		BossPunchComp.bWithinSlowMotionWindow = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossPunchComp.AnimData.bPunchingThisFrame = false;

		if(Boss != nullptr)
			Boss.SetPunchingThisFrame(false, BossPunchComp.Type, -1);

		if(BossPunchComp.Type == ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch && BossPunchComp.AmountOfPunchesPerformed == BossPunchComp.TypeSettings.BossPunchesAmount)
		{
			if(Boss != nullptr)
				Boss.SetLastFinalPunchThisFrame(false);

			BossPunchComp.AnimData.bShouldPlayLastFinalPunch = false;
		}
	}

	ATundraBoss TryGetBoss()
	{
		if(Boss == nullptr)
			Boss = TundraBossArena::GetTundraBoss();
	
		return Boss;
	}
}