class UTundraPlayerSnowMonkeyIceKingBossPunchTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyBossPunching);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyBossPunch);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerSnowMonkeyIceKingBossPunchComponent BossPunchComp;
	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	bool bCanPunch = false;
	float TimeOfCanPunch = -100.0;

	FTutorialPrompt Prompt;
	default Prompt.Action = ActionNames::PrimaryLevelAbility;
	default Prompt.Mode = ETutorialPromptMode::RemoveWhenPressed;

	ATundraBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Player);
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bool bNewCanPunch = BossPunchComp.CanPunch();
		if(bNewCanPunch && !bCanPunch)
			TimeOfCanPunch = Time::GetGameTimeSeconds();

		bCanPunch = bNewCanPunch;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!bCanPunch)
			return false;

		if(Time::GetGameTimeSince(TimeOfCanPunch) < 0.1)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bCanPunch)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("BossPunchComp.AmountOfPunchesPerformed: " + BossPunchComp.AmountOfPunchesPerformed, 5);

		FName TutorialAttachSocket;

		if(BossPunchComp.CurrentBossPunchInteractionActor.Type == ETundraPlayerSnowMonkeyIceKingBossPunchType::FinalPunch)
			TutorialAttachSocket = n"RightHand";
		else if(BossPunchComp.AmountOfPunchesPerformed == 1 || BossPunchComp.AmountOfPunchesPerformed == 3 || BossPunchComp.AmountOfPunchesPerformed == 4)
			TutorialAttachSocket = n"LeftHand";
		else
			TutorialAttachSocket = n"RightHand";

		Player.ShowTutorialPromptWorldSpace(Prompt, this, SnowMonkeyComp.GetShapeActor().Mesh, FVector::UpVector * 50, 0, TutorialAttachSocket);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	ATundraBoss TryGetBoss()
	{
		if(Boss == nullptr)
			Boss = TundraBossArena::GetTundraBoss();
	
		return Boss;
	}
}