enum ETiltingWorldCameraResetType
{
    None,
    Delay,
    Instant
}

class UTiltingWorldSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "Mio|Tilt|Input")
    float TiltSpeed = 100.0;

    UPROPERTY(Category = "Mio|Tilt|Input")
    float TiltAcceleration = 1.0;

    /**
     * Tweak the Roll speed independent of pitch.
     * Change polarity to change direction.
     */
    UPROPERTY(Category = "Mio|Tilt|Input")
    float RollMultiplier = 1.0;

    /**
     * Tweak the Pitch speed independent of roll.
     * Change polarity to change direction.
     */
    UPROPERTY(Category = "Mio|Tilt|Input")
    float PitchMultiplier = 1.0;

    UPROPERTY(Category = "Mio|Tilt|Clamping")
    bool bClampTilt = true;

    UPROPERTY(Category = "Mio|Tilt|Clamping")
    float ClampAngle = 45.0;

    UPROPERTY(Category = "Mio|Tilt|Clamping")
    bool bAllowPitching = true;

    /**
     * If we just clamp the angles, the tilting would have a rectangular "shape" when viewed from above.
     * We can clamp the rotation to a cone to get a circular "shape".
     */
    UPROPERTY(Category = "Mio|Tilt|Clamping")
    bool bClampTiltToCone = true;

    /**
     * Clamp the internal rotation as well, this changes the tilting input so that
     * the viewed rotation and the internal rotation is the same.
     */
    UPROPERTY(Category = "Mio|Tilt|Clamping")
    bool bClampTiltInternalToCone = true;

    /**
     * Zoes WalkableSlope will be ClampAngle + WalkableSlopeAngleMargin.
     */
    UPROPERTY(Category = "Zoe|Movement")
    float WalkableSlopeAngleMargin = 5.0;

	UPROPERTY(Category = "Zoe|Camera")
    bool bDisableCamera = false;

    UPROPERTY(Category = "Zoe|Camera", Meta = (EditCondition = "!bDisableCamera"))
    float CameraRotateSpeed = 100.0;

    UPROPERTY(Category = "Zoe|Camera", Meta = (EditCondition = "!bDisableCamera"))
    float CameraRotateAcceleration = 1.0;

    UPROPERTY(Category = "Zoe|Camera", Meta = (EditCondition = "!bDisableCamera"))
    float CameraClampAngle = 20.0;

    UPROPERTY(Category = "Zoe|Camera", Meta = (EditCondition = "!bDisableCamera"))
    ETiltingWorldCameraResetType ResetCameraType = ETiltingWorldCameraResetType::Delay;

    UPROPERTY(Category = "Zoe|Camera", Meta = (EditCondition = "!bDisableCamera"))
    float CameraResetDelay = 1.0;

    UPROPERTY(Category = "Zoe|Camera")
    UHazeCameraSpringArmSettingsDataAsset CameraSettings;
}