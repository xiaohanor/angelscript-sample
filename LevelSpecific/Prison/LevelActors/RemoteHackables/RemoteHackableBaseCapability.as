class URemoteHackableBaseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"RemoteHackable");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	URemoteHackingResponseComponent HackingResponseComp;
	AHazePlayerCharacter Player;
	UHazeMovementComponent PlayerMoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HackingResponseComp = URemoteHackingResponseComponent::Get(Owner);
		Player = Drone::GetSwarmDronePlayer();
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HackingResponseComp.bHacked)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HackingResponseComp.bHacked)
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}