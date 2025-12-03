enum ESpinningWorldType
{
    CameraAligned,
    WorldAligned
}

class USpinningWorldSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "Mio|Spin")
    float SpinSpeed = 100.0;

    UPROPERTY(Category = "Mio|Spin")
    float SpinAcceleration = 1.0;

    /**
     * Tweak the Roll speed independent of pitch.
     * Change polarity to change direction.
     */
    UPROPERTY(Category = "Mio|Spin")
    float RollMultiplier = 1.0;

    /**
     * Tweak the Pitch speed independent of roll.
     * Change polarity to change direction.
     */
    UPROPERTY(Category = "Mio|Spin")
    float PitchMultiplier = 1.0;

    UPROPERTY(Category = "Mio|Spin")
    ESpinningWorldType SpinningWorldType;

    /**
     * Zoes WalkableSlope will be ClampAngle + WalkableSlopeAngleMargin.
     */
    UPROPERTY(Category = "Zoe|Movement")
    float WalkableSlopeAngle = 45.0;

    UPROPERTY(Category = "Zoe|Camera")
	bool bUseFollowCam = false;

    UPROPERTY(Category = "Zoe|Camera", Meta = (EditCondition = "bUseFollowCam"))
	float FollowCamSpeed = 0.5;

    UPROPERTY(Category = "Zoe|Camera")
    UHazeCameraSpringArmSettingsDataAsset CameraSettings;
}