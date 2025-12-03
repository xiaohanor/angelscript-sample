class ASplineScenepointActor : AScenepointActorBase
{
#if EDITOR
	default Billboard.SpriteName = "SplineScenepoint";
#endif	

#if EDITOR
	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComponent;
	default ArrowComponent.SetRelativeLocation(FVector(20.0, 0.0, 0.0));
	default ArrowComponent.ArrowSize = 2.0;
	default ArrowComponent.ArrowColor = FLinearColor::LucBlue;
#endif

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly) 
	UHazeSplineComponent SplineComponent;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UScenepointComponent ScenepointComponent;

	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};
}
