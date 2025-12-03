class USummitMioFakeFlyingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(BabyDragon::BabyDragon);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 35;
	default TickGroupSubPlacement = 9;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerAcidBabyDragonComponent DragonComp;
	USteppingMovementData Movement;
	USummitMioFakeFlyingComponent FakeFlyingComp;
	UPlayerFloorMotionComponent JogComp;

	float TraveledDistance = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FakeFlyingComp = USummitMioFakeFlyingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!FakeFlyingComp.bIsFakeFlying)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!FakeFlyingComp.bIsFakeFlying)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp = UPlayerAcidBabyDragonComponent::Get(Player);
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"BackpackDragonHover", this);

		DragonComp.RequestBabyDragonLocomotion(n"BackpackDragonHover");
	}
};