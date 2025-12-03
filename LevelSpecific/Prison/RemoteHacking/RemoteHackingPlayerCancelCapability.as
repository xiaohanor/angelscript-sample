class URemoteHackingPlayerCancelCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"ExoSuit");
	default CapabilityTags.Add(n"RemoteHackingCancel");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	URemoteHackingPlayerComponent HackingPlayerComp;

	float TimeSinceInput = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HackingPlayerComp = URemoteHackingPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HackingPlayerComp.bHackActive)
			return false;

		if (Player.IsPlayerDead())
			return true;

		if (!WasActionStarted(ActionNames::Cancel))
			return false;

		if (!HackingPlayerComp.CurrentHackingResponseComp.bCanCancel)
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
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		HackingPlayerComp.StopHacking();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}