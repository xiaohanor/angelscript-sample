/**
 * 
 */
class USketchbookArrowSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Launching")
    float MinLaunchSpeed = 400.0;

    UPROPERTY(Category = "Launching")
    float MaxLaunchSpeed = 1000.0;

	UPROPERTY(Category = "Launching")
    float MaxTargetVelocity = 800.0;

    UPROPERTY(Category = "Gravity")
    float MinChargeGravity = 600.0;

    UPROPERTY(Category = "Gravity")
    float MaxChargeGravity = 300.0;

    UPROPERTY(Category = "Hit")
    float HitImpulseScale = 0.2;
}

namespace SketchbookArrow
{
    const FName DebugCategory = n"SketchbookArrow";
    const FName SketchbookArrowTag = n"SketchbookArrow";
}