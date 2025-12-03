class USpinningWorldZoePlayerAlignWithSpinCapability : UHazePlayerCapability
{
    USpinningWorldZoeComponent PlayerComp;
    USpinningWorldMioComponent MioComp;
    UHazeMovementComponent MoveComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = USpinningWorldZoeComponent::Get(Player);
        MioComp = USpinningWorldMioComponent::Get(Game::GetMio());
        MoveComp = UHazeMovementComponent::Get(Player);
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
    void OnActivated()
    {
        UMovementStandardSettings::SetWalkableSlopeAngle(Player, MioComp.Settings.WalkableSlopeAngle, this);
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated()
    {
        UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        Player.OverrideGravityDirection(-MioComp.SmoothWorldRotation.UpVector, this);
    }
}