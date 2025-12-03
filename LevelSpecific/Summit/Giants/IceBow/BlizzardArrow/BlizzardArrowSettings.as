/**
 * 
 */
class UBlizzardArrowSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "Launching")
    float LaunchSpeed = 5000.0;

    UPROPERTY(Category = "Gravity")
    float Gravity = 500.0;

    UPROPERTY(Category = "Hit")
    float HitImpulseScale = 0.05;

    UPROPERTY(Category = "Hit")
    bool bRequireWindJavelinTag = true;

    UPROPERTY(Category = "Hit")
	float Lifetime = 6.0;
}

namespace BlizzardArrow
{
    const FName DebugCategory = n"BlizzardArrow";
    const FName BlizzardArrowCapabilityTag = n"BlizzardArrowCapability";
}