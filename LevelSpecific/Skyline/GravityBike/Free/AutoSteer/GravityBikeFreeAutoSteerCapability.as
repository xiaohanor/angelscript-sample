class UGravityBikeFreeAutoSteerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeInput);

    default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 110;	// After UGravityBikeFreeInputCapability

    AGravityBikeFree GravityBike;
	UPlayerTargetablesComponent PlayerTargetablesComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        GravityBike = Cast<AGravityBikeFree>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if(GravityBike.GetDriver() == nullptr)
			return false;

		if(GravityBike.HasExploded())
			return false;

		if(ShouldBlockInputFromAlignWithWall() && GravityBikeFree::WallAlign::WallAlignBlockSteeringInput)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(GravityBike.GetDriver() == nullptr)
			return true;

		if(GravityBike.HasExploded())
			return true;

		if(ShouldBlockInputFromAlignWithWall() && GravityBikeFree::WallAlign::WallAlignBlockSteeringInput)
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(GravityBike.GetDriver());
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		const UGravityBikeFreeAutoSteerTargetComponent AutoSteerTarget = PlayerTargetablesComp.GetPrimaryTarget(UGravityBikeFreeAutoSteerTargetComponent);
		if(AutoSteerTarget == nullptr)
			return;

		const float AutoSteerInput = AutoSteerTarget.GetAutoSteerInput(GravityBike);
		const float PlayerSteerInput = GravityBike.Input.Steering;
		if(Math::Abs(AutoSteerInput) > Math::Abs(PlayerSteerInput))
			GravityBike.Input.Steering = AutoSteerInput;
		else
			GravityBike.Input.Steering += AutoSteerInput;

		GravityBike.Input.Steering = Math::Clamp(GravityBike.Input.Steering, -1, 1);
    }

	bool ShouldBlockInputFromAlignWithWall() const
	{
		if(!GravityBikeFree::WallAlign::WallAlignBlockInput)
			return false;

		if(GravityBike.AlignedWithWallTime < 0)
			return false;

		return Time::GetGameTimeSince(GravityBike.AlignedWithWallTime) < GravityBikeFree::WallAlign::WallAlignInputBlockDuration;
	}
};