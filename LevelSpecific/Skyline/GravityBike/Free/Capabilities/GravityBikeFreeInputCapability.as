class UGravityBikeFreeInputCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeInput);

    default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

    AGravityBikeFree GravityBike;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        GravityBike = Cast<AGravityBikeFree>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if(!GravityBike.HasControl())
			return false;

		if(GravityBike.HasExploded())
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(GravityBike.HasExploded())
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
		GravityBike.Input.Reset();
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		TickThrottle();
		TickSteering();
		TickDrift();
    }

	void TickThrottle()
	{
		if(!GravityBike.ForcedThrottle.IsDefaultValue())
		{
			GravityBike.Input.Throttle = GravityBike.ForcedThrottle.Get();
			return;
		}

		if(ShouldBlockInputFromAlignWithWall() && GravityBikeFree::WallAlign::WallAlignBlockThrottleInput)
		{
			GravityBike.Input.Throttle = 0;
			return;
		}

		GravityBike.Input.Throttle = Math::Max(GetAttributeFloat(AttributeNames::Accelerate), 0);

		// Force throttle while boosting
		if(GravityBike.IsBoosting())
			GravityBike.Input.Throttle = 1.0;
	}

	void TickSteering()
	{
		if(!GravityBike.ForcedSteering.IsDefaultValue())
		{
			GravityBike.Input.Steering = GravityBike.ForcedSteering.Get();
			return;
		}

		if(ShouldBlockInputFromAlignWithWall() && GravityBikeFree::WallAlign::WallAlignBlockSteeringInput)
		{
			GravityBike.AccSteering.SnapTo(0);
			GravityBike.Input.Steering = 0;
			return;
		}

        GravityBike.Input.Steering = GetAttributeFloat(AttributeNames::MoveRight);
	}

	void TickDrift()
	{
		if(ShouldBlockInputFromAlignWithWall())
		{
			GravityBike.Input.bDrift = false;
			GravityBike.Input.bTappedDrift = false;
			return;
		}

		GravityBike.Input.bDrift = IsActioning(GravityBikeFree::Input::DriftAction);
		GravityBike.Input.bTappedDrift = WasActionStarted(GravityBikeFree::Input::DriftAction);
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