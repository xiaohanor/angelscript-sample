class USpinningWorldMioSpinCapability : UHazePlayerCapability
{
    USpinningWorldMioComponent PlayerComp;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        PlayerComp = USpinningWorldMioComponent::Get(Player);
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
    void TickActive(float DeltaTime)
    {
        FRotator SpinRotation = FRotator::ZeroRotator;
        const FVector2D InputVector = MioFullScreen::GetStickInput(this);

        SpinRotation.Roll += (InputVector.X * PlayerComp.Settings.SpinSpeed * PlayerComp.Settings.RollMultiplier * DeltaTime);
        SpinRotation.Pitch -= (InputVector.Y * PlayerComp.Settings.SpinSpeed * PlayerComp.Settings.PitchMultiplier * DeltaTime);

        FQuat WorldRotation;
        switch(PlayerComp.Settings.SpinningWorldType)
        {
            case ESpinningWorldType::CameraAligned:
            {
                FTransform ViewTransform = Game::GetZoe().ViewTransform;

                FQuat WorldRotationRelativeToCamera = ViewTransform.InverseTransformRotation(PlayerComp.WorldRotation_Internal.Quaternion());
                FQuat NewWorldRotationRelativeToCamera = SpinRotation.Quaternion() * WorldRotationRelativeToCamera;
                WorldRotation = ViewTransform.TransformRotation(NewWorldRotationRelativeToCamera);
                break;
            }

            case ESpinningWorldType::WorldAligned:
            {
                
                WorldRotation = SpinRotation.Quaternion() * PlayerComp.WorldRotation_Internal.Quaternion();
                break;
            }

            default:
                check(false);  // Unhandled case
                break;
        }

        Print("WorldRotation: " + WorldRotation.Rotator().ToString(), 0.0);
        PlayerComp.SetWorldRotation(WorldRotation.Rotator());
        PlayerComp.UpdateSmoothWorldRotation(DeltaTime);
    }
}