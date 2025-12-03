UCLASS(Abstract)
class USpinningWorldMioComponent : UActorComponent
{
    UPROPERTY()
    USpinningWorldSettings Settings;

    access SpinningWorldInternal = private, USpinningWorldMioSpinCapability;
    
    access: SpinningWorldInternal
    FRotator WorldRotation_Internal = FRotator::ZeroRotator;

    access: SpinningWorldInternal
    FHazeAcceleratedRotator AccWorldRotation;

    void UpdateSmoothWorldRotation(float DeltaTime)
    {
        AccWorldRotation.AccelerateTo(WorldRotation_Internal, 1.0 / Settings.SpinAcceleration, DeltaTime);
    }

    FRotator GetSmoothWorldRotation() const property
    {
        return AccWorldRotation.Value;
    }

    void SetWorldRotation(FRotator InRotation)
    {
        WorldRotation_Internal = InRotation;
    }
}