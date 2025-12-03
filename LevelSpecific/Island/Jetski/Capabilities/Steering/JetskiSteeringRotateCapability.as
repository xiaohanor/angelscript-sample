class UJetskiSteeringRotateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

    default TickGroup = EHazeTickGroup::Input;
    default TickGroupOrder = 100;

    AJetski Jetski;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Jetski = Cast<AJetski>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if(Jetski.Settings.SteeringMode != EJetskiSteeringMode::Rotate)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(Jetski.Settings.SteeringMode != EJetskiSteeringMode::Rotate)
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		const float Steering = Jetski.Input.GetSteering();

        float SteeringDuration = Jetski.Settings.SteeringDuration;
        if(Math::Abs(Steering) < 0.2)
            SteeringDuration = Jetski.Settings.SteeringReturnDuration;

        Jetski.AccSteering.AccelerateTo(Steering, SteeringDuration, DeltaTime);
    }
}