class ULightCrowdBirdCameraCapability : UHazePlayerCapability
{
    default CapabilityTags.Add(LightCrowdTags::LightCrowd);
    default CapabilityTags.Add(LightCrowdTags::LightCrowdMioBird);
    default CapabilityTags.Add(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInFullScreen);

    ULightCrowdBirdComponent PlayerComp;
    ULightCrowdPlayerComponent LightCrowdComp;
    UCameraUserComponent CameraUser;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = ULightCrowdBirdComponent::Get(Player);
        LightCrowdComp = ULightCrowdPlayerComponent::GetOrCreate(Game::Zoe);
        CameraUser = UCameraUserComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(LightCrowdComp.State != ELightCrowdState::MioBird)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(LightCrowdComp.State != ELightCrowdState::MioBird)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FVector ToZoeDir = (Game::Zoe.ActorLocation - Player.ActorLocation).GetSafeNormal();
        CameraUser.SetDesiredRotation(ToZoeDir.Rotation(), this);
    }

    ULightCrowdSettings GetSettings() const property
    {
        return LightCrowdComp.Settings;
    }
}