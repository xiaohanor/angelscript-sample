class UTundraBouncyMushroomBounceCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UTundraPlayerShapeshiftingComponent ShapeComp;
	UPlayerAirDashComponent DashComp;
	UPlayerAirJumpComponent AirJumpComp;
	UTundraMushroomPlayerBounceComponent BounceComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BounceComp = UTundraMushroomPlayerBounceComponent::GetOrCreate(Player);
		ShapeComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		DashComp = UPlayerAirDashComponent::Get(Player);
		AirJumpComp = UPlayerAirJumpComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Time::FrameNumber != BounceComp.BounceFrame +1)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > 0.5)
			return true;

		if(DashComp.IsAirDashing())
			return true;

		if(AirJumpComp.bPerformedDoubleJump)
			return true;

		if(Player.IsOnWalkableGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(ShapeComp == nullptr)
			ShapeComp = UTundraPlayerShapeshiftingComponent::Get(Player);

		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyAirborneGroundSlam, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyAirborneGroundSlam, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ShapeComp.ActiveShapeType != ETundraShapeshiftActiveShape::Player)
			return;

		if(Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"Jump", this);
	}
};