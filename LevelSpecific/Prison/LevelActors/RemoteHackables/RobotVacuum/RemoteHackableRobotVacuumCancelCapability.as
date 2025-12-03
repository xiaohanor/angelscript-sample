class URemoteHackableRobotVacuumCancelCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"RobotVacuumCancel");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	URemoteHackingPlayerComponent HackingPlayerComp;
	ARemoteHackableRobotVacuum RobotVacuum;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		RobotVacuum = Cast<ARemoteHackableRobotVacuum>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowCancelPrompt(this);
		HackingPlayerComp = URemoteHackingPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveCancelPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::Cancel))
		{
			CrumbStopHacking();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbStopHacking()
	{
		HackingPlayerComp.StopHacking();
	}
}