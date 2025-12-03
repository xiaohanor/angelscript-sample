/**
 * 
 */
class UWindArrowSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Player Knockdown")
	float ExtraPlayerKnockdownRadius = 200.0;

	UPROPERTY(Category = "Launching")
    float MinLaunchSpeed = 3000.0;

    UPROPERTY(Category = "Launching")
    float MaxLaunchSpeed = 5000.0;

    UPROPERTY(Category = "Gravity")
    float MinChargeGravity = 0.0;

    UPROPERTY(Category = "Gravity")
    float MaxChargeGravity = 0.0;

    UPROPERTY(Category = "Hit")
    float HitImpulseScale = 0.05;
}

namespace WindArrow
{
    const FName DebugCategory = n"WindArrow";
    const FName WindArrowTag = n"WindArrow";
}