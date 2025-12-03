class UGameShowArenaPlayerRagdollCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::Movement;

	UGameShowArenaBombTossPlayerComponent BombTossComp;

	default DebugCategory = n"GameShow";

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossComp = UGameShowArenaBombTossPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BombTossComp.bIsRagdolling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BombTossComp.bIsRagdolling)
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
		Player.ActorLocation = Player.Mesh.WorldLocation;
	}
};