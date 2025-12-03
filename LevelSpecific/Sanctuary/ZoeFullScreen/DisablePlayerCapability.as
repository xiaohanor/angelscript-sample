class UDisablePlayerCapability : UHazePlayerCapability
{
    default CapabilityTags.Add(n"DisablePlayer");

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
    void OnActivated()
    {
        Player.BlockCapabilities(CapabilityTags::Movement, this);
        Player.BlockCapabilities(CapabilityTags::Camera, this);
        Player.BlockCapabilities(CapabilityTags::Visibility, this);
        Player.BlockCapabilities(CapabilityTags::Collision, this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Player.UnblockCapabilities(CapabilityTags::Movement, this);
        Player.UnblockCapabilities(CapabilityTags::Camera, this);
        Player.UnblockCapabilities(CapabilityTags::Visibility, this);
        Player.UnblockCapabilities(CapabilityTags::Collision, this);
    }
}