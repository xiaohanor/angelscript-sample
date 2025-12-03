UCLASS(Abstract)
class UIslandPushKnockEffectHandler : UHazeEffectEventHandler
{

    // The owner hit a target (PushKnock.SelfImpact)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void SelfImpact() {}

	// The target got hit by owner (PushKnock.TargetImpact)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void TargetImpact(FIslandPushKnockImpactParams Params) {}
}

struct FIslandPushKnockImpactParams
{
    UPROPERTY()
    FVector ImpactLocation;
	UPROPERTY()
    FRotator ImpactRotation;
};