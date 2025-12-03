class USummitRollingLiftPassengerRespawnCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerTailTeenDragonComponent DragonComp;
	USummitTeenDragonRollingLiftComponent RollingLiftComp;
	UPlayerRespawnComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollingLiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(RollingLiftComp.CurrentRollingLift == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(RollingLiftComp.CurrentRollingLift == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawned");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RespawnComp.OnPlayerRespawned.Unbind(this, n"OnRespawned");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		Player.ActorRelativeLocation = FVector::ZeroVector;
	}
};