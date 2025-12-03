class AAnimationScenepointActor : AScenepointActorBase
{
#if EDITOR
	default Billboard.SpriteName = "AnimationScenepoint";
#endif	

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComponent;
	default ArrowComponent.SetRelativeLocation(FVector(20.0, 0.0, 0.0));
	default ArrowComponent.ArrowSize = 2.0;
	default ArrowComponent.ArrowColor = FLinearColor::Yellow;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly) 
	UScenepointAnimationComponent AnimationComponent;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UScenepointComponent ScenepointComponent;

	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};
}
