UCLASS(Abstract)
class USanctuaryUnseenEffectHandler : UHazeEffectEventHandler
{

    // The owner took a step while chasing (SanctuaryUnseen.ChaseStep)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void ChaseStep() {}
}