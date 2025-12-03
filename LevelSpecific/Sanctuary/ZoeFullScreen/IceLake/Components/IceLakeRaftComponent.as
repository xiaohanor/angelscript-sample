/**
 * Data component to allow a HazeScriptComponentVisualizer
 */
class UIceLakeRaftComponent : UActorComponent
{
    UPROPERTY(EditAnywhere, Category = "Ice Lake Raft")
	float MinAffectDistance = 2000.0;

    UPROPERTY(EditAnywhere, Category = "Ice Lake Raft")
	float MaxAffectDistance = 3000.0;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if(MinAffectDistance < 0)
            MinAffectDistance = 0;

        if(MaxAffectDistance < 0)
            MaxAffectDistance = 0;

        if(MaxAffectDistance < MinAffectDistance)
        {
            MaxAffectDistance = MinAffectDistance + 1.0;
        }
    }
}

class UIceLakeRaftComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIceLakeRaftComponent;

    UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent InComponent)
	{
		const auto Component = Cast<UIceLakeRaftComponent>(InComponent);
		if(Component == nullptr)
			return;

        const auto Actor = Cast<AIceLakeRaft>(InComponent.Owner);
        if(Actor == nullptr)
            return;

		SetRenderForeground(false);

        DrawWireSphere(Actor.ActorLocation, Component.MinAffectDistance, FLinearColor::Green);
        DrawWireSphere(Actor.ActorLocation, Component.MaxAffectDistance, FLinearColor::Red);
	}
}