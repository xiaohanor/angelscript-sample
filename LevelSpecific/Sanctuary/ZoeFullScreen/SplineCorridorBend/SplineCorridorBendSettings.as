class USplineCorridorBendSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "Mio|Bend")
    float BendSpeed = 1.0;

    UPROPERTY(Category = "Mio|Bend")
    float BendAcceleration = 1.0;

    UPROPERTY(Category = "Zoe|Camera")
    UHazeCameraSpringArmSettingsDataAsset CameraSettings;
}