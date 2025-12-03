class UGravityBikeSplineBoostSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Forward")
    float BoostDragFactor = 30;

    UPROPERTY(Category = "Boost")
    float MaxBoostTime = 1.5;

    UPROPERTY(Category = "Boost")
    float BoostAcceleration = 0;

    UPROPERTY(Category = "Boost|Timed Boost")
    float BoostChargeDuration = 1.0;

    UPROPERTY(Category = "Boost|FOV")
    float BoostFOVAdditive = 10;
};