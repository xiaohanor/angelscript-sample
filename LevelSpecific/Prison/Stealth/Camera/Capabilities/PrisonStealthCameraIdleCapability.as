class UPrisonStealthCameraIdleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthCamera);

	APrisonStealthCamera StealthCamera;
    UPrisonStealthVisionComponent VisionComponent;
	UPrisonStealthStunnedComponent StunnedComp;
	UPrisonStealthDetectionComponent DetectionComp;
    float SwivelTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StealthCamera = Cast<APrisonStealthCamera>(Owner);
        VisionComponent = UPrisonStealthVisionComponent::Get(Owner);
		StunnedComp = UPrisonStealthStunnedComponent::Get(Owner);
		DetectionComp = UPrisonStealthDetectionComponent::Get(Owner);
	}

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if(StunnedComp.IsStunned())
			return false;

        if(StealthCamera.HasSpottedAnyPlayer())
            return false;

        if(StealthCamera.HasDetectedAnyPlayer())
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(StunnedComp.IsStunned())
			return true;

        if(StealthCamera.HasSpottedAnyPlayer())
            return true;

        if(StealthCamera.HasDetectedAnyPlayer())
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        SwivelTime += DeltaTime;
        StealthCamera.TargetPitch = Math::Sin(SwivelTime * StealthCamera.SwivelFrequency) * StealthCamera.SwivelAmount;

        const FRotator Rotation = Math::RInterpTo(StealthCamera.Camera.RelativeRotation, FRotator(StealthCamera.TargetPitch, 0.0, 0.0), DeltaTime, StealthCamera.RotationInterpSpeed);
		StealthCamera.Camera.SetRelativeRotation(Rotation);
    }
}