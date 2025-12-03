class UTiltingWorldMioComponent : UActorComponent
{
    UPROPERTY()
    UTiltingWorldSettings Settings;

    access TiltingWorldInternal = private, UTiltingWorldMioTiltCapability;
    
    access: TiltingWorldInternal
    FRotator WorldRotation_Internal = FRotator::ZeroRotator;

    access: TiltingWorldInternal
    FHazeAcceleratedRotator AccWorldRotation;

    void UpdateSmoothWorldRotation(float DeltaTime)
    {
        AccWorldRotation.AccelerateTo(WorldRotation_Internal, 1.0 / Settings.TiltAcceleration, DeltaTime);
    }

    FRotator GetSmoothWorldRotation() const property
    {
        return AccWorldRotation.Value;
    }

    void SetWorldRotation(FRotator InRotation)
    {
        WorldRotation_Internal = InRotation;
        if(Settings.bClampTiltInternalToCone)
            WorldRotation_Internal = ClampToCone(WorldRotation_Internal);
    }

    FRotator ClampToCone(FRotator Rotation)
    {
        if(!Settings.bClampTilt || !Settings.bClampTiltToCone)
            return Rotation;

        FQuat CurrentRotation = Rotation.Quaternion();
        FVector RotationVec = CurrentRotation.RotationAxis * CurrentRotation.Angle;

        RotationVec = RotationVec.ConstrainToPlane(FVector::UpVector);

        // Clamp length of rotation, effectively limiting the rotation to a cone
        float ConeAngleRad = Math::DegreesToRadians(Settings.ClampAngle);
        float RotationAngle = RotationVec.SizeSquared();
        if (RotationAngle > Math::Square(ConeAngleRad))
        {
            FVector CollisionRotationNormal = RotationVec.SafeNormal;
            FVector ClampedRotation = CollisionRotationNormal * ConeAngleRad;
            CurrentRotation = FQuat(ClampedRotation.UnsafeNormal, ClampedRotation.Size());
        }

        return CurrentRotation.Rotator();
    }
}