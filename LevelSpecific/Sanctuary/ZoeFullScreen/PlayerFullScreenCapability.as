class UPlayerFullScreenCapability : UHazePlayerCapability
{
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
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        Player.ClearCameraSettingsByInstigator(this);
    }
}