class ASkylineEnforcerJumpEntranceScenepoint : AScenepointActorBase
{
	UPROPERTY(DefaultComponent)
	USkylineEnforcerJumpEntranceScenepointVisualizerComponent VisualizerComp;

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComponent;
	default ArrowComponent.SetRelativeLocation(FVector(0.0, 0.0, 0.0));
	default ArrowComponent.ArrowSize = 3.0;
	default ArrowComponent.ArrowColor = FLinearColor::Red;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UScenepointComponent ScenepointComponent;
	default ScenepointComponent.CooldownDuration = 0.25;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TArray<ASkylineEnforcerJumpEntranceScenepoint> LinkedScenepoints;

	UPROPERTY(EditInstanceOnly)
	float JumpDistance;

	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};
}

class USkylineEnforcerJumpEntranceScenepointVisualizerComponent : UActorComponent
{

}

#if EDITOR
class USkylineEnforcerJumpEntranceScenepointVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USkylineEnforcerJumpEntranceScenepointVisualizerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        ASkylineEnforcerJumpEntranceScenepoint ScenepointActor = Cast<ASkylineEnforcerJumpEntranceScenepoint>(Component.Owner);
		UScenepointComponent Scenepoint = ScenepointActor.GetScenepoint();

		// happens on teardown on the owner
		if(ScenepointActor == nullptr)
			return;
    }   
} 
#endif