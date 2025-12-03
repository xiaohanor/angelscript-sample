/**
 * 
 */
class UIceArrowSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Launching")
    float MinLaunchSpeed = 3000.0;

    UPROPERTY(Category = "Launching")
    float MaxLaunchSpeed = 5000.0;

    UPROPERTY(Category = "Gravity")
    float MinChargeGravity = 1000.0;

    UPROPERTY(Category = "Gravity")
    float MaxChargeGravity = 500.0;

    UPROPERTY(Category = "Hit")
    float HitImpulseScale = 0.05;
}

namespace IceArrow
{
    const FName DebugCategory = n"IceArrow";
    const FName IceArrowTag = n"IceArrow";
}