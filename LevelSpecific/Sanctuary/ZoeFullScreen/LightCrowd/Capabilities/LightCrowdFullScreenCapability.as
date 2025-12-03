class ULightCrowdFullScreenCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(LightCrowdTags::LightCrowd);
	default CapabilityTags.Add(LightCrowdTags::LightCrowdFullScreen);
	default CapabilityTags.Add(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInMioBird);

    ULightCrowdPlayerComponent PlayerComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = ULightCrowdPlayerComponent::Get(Player);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
        if(PlayerComp.State != ELightCrowdState::CrowdNoMio)
            return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
        if(PlayerComp.State != ELightCrowdState::CrowdNoMio)
            return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::Slow);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
    }

    ULightCrowdSettings GetSettings() const property
    {
        return PlayerComp.Settings;
    }
}