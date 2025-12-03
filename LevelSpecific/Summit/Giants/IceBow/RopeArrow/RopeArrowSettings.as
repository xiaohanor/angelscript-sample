/**
 * 
 */
class URopeArrowSettings : UHazeComposableSettings
{
    UPROPERTY(Category = "Launching")
    float LaunchSpeed = 5000.0;

    UPROPERTY(Category = "Gravity")
    float Gravity = 500.0;

    UPROPERTY(Category = "Perch Spline")
    TSubclassOf<APerchSpline> PerchSplineClass;

    UPROPERTY(Category = "Pole Climb")
    TSubclassOf<APoleClimbActor> PoleClimbActorClass;
}

namespace RopeArrow
{
    const FName DebugCategory = n"RopeArrow";
    const FName RopeArrowTag = n"RopeArrow";
}