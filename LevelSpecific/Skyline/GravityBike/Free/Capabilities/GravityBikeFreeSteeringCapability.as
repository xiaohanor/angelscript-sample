class UGravityBikeFreeSteeringCapability : UHazeCapability
{
    default CapabilityTags.Add(CapabilityTags::Movement);
    default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeSteering);

    default TickGroup = EHazeTickGroup::Input;
    default TickGroupOrder = 120;

    AGravityBikeFree GravityBike;
    AHazePlayerCharacter Player;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        GravityBike = Cast<AGravityBikeFree>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        return false;
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.AccSteering.SnapTo(0);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        float Steering = GravityBike.Input.Steering;

		Steering *= GravityBike.Settings.SteeringMultiplier;

        float SteeringDuration = GravityBike.Settings.SteeringDuration;
        if(Math::Abs(Steering) < 0.2)
            SteeringDuration = GravityBike.Settings.SteeringReturnDuration;

        GravityBike.AccSteering.AccelerateTo(Steering, SteeringDuration, DeltaTime);
    }
}