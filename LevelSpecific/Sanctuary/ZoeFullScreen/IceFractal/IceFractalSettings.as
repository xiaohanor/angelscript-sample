class UIceFractalSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Fractal")
    TSubclassOf<AIceFractal> IceFractalClass;

	// Time in seconds between each fractal spawning.
	UPROPERTY(Category = "Fractal")
    float SpawnInterval = 0.5;

	// How long each fractal should live. Determines the animation speed.
    UPROPERTY(Category = "Fractal")
    float LifeTime = 10.0;

    UPROPERTY(Category = "Fractal")
    bool bUseStaticMovementPlane = true;

    UPROPERTY(Category = "Fractal|Keep Distance")
    bool bKeepDistanceFromPlayer = true;

    UPROPERTY(Category = "Fractal|Keep Distance", Meta = (EditCondition = "bKeepDistanceFromPlayer"))
    float KeepDistanceDistance = 2500.0;

    UPROPERTY(Category = "Fractal|Speed")
    bool bConstantSpeed = true;

    UPROPERTY(Category = "Fractal|Speed", Meta = (EditCondition = "bConstantSpeed"))
    float Speed = 1.0;

    UPROPERTY(Category = "Fractal|Speed", Meta = (EditCondition = "!bConstantSpeed"))
    float MinSpeed = 0.2;

    UPROPERTY(Category = "Fractal|Speed", Meta = (EditCondition = "!bConstantSpeed"))
    float MaxSpeed = 3.0;

	// Curve from 0 to 1 to determine the speed.
    UPROPERTY(Category = "Fractal|Speed")
    UCurveFloat SpeedCurve;

	// Needs to be manually adjusted when MaxScale is changed!
	UPROPERTY(Category = "Fractal|Speed")
    float MaxDistance = 5400;

	// Curve from 0 to 1 to determine the acceleration of the scaling.
    UPROPERTY(Category = "Fractal|Scale")
    UCurveFloat ScaleCurve;

    UPROPERTY(Category = "Fractal|Scale")
    float MaxScale = 10.0;

	// Curve from 0 to 1 to determine the acceleration of the height.
    UPROPERTY(Category = "Fractal|Height")
    UCurveFloat HeightCurve;

    UPROPERTY(Category = "Fractal|Height")
    float MaxHeightOffset = 1000.0;

    UPROPERTY(Category = "Fractal|Movement")
    bool bBlockJump = false;

	UPROPERTY(Category = "Fractal|Movement")
    bool bBlockAirJump = false;
	
	UPROPERTY(Category = "Fractal|Movement")
    bool bBlockDash = false;

	UPROPERTY(Category = "Fractal|Movement")
    bool bBlockSprint = false;

	UPROPERTY(Category = "Camera")
	float CameraInputDelay = 1.0;
	UPROPERTY(Category = "Camera")
	float CameraInputYawClamp = 10.0;
	UPROPERTY(Category = "Camera")
	float CameraInputPitchClamp = 10.0;
	UPROPERTY(Category = "Camera")
	float CameraInputSensitivity = 1.0;
	UPROPERTY(Category = "Camera")
	float CameraInputDuration = 0.5;
}