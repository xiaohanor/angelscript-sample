/*
class UMovingActorSplineComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMovingActorSplineVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto AMovingActor = Cast<AMovingActor>(Component.Owner);
	}
}
*/

class UMovingActorSplineVisualizerComponent : UActorComponent
{

}

enum EMovingActorType
{
	AbsoluteKeyPoints,
	RelativeKeyPoints,
	SplineKeyPoints
}

class AMovingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMovingSceneComponent MovingComponent;

	UPROPERTY(EditAnywhere)
	EMovingActorType Type;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UMovingActorSplineComponent SplineComponent;

	UPROPERTY(EditInstanceOnly)
	float PreviewTime = 0.0;

//	UPROPERTY(DefaultComponent)
//	UMovingActorSplineVisualizerComponent MovingActorSplineVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MovingComponent.Spline = SplineComponent;
		AttachChildsToComponent(MovingComponent);
		MovingComponent.Preview(PreviewTime);

		
		Debug::DrawDebugArrow(SplineComponent.GetWorldLocationAtSplineDistance(SplineComponent.SplineLength), SplineComponent.GetWorldLocationAtSplineDistance(SplineComponent.SplineLength) + SplineComponent.SplinePoints[1].RelativeRotation.ForwardVector * 100.0, 15.0, Duration = 10.0);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovingComponent.Spline = SplineComponent;
		AttachChildsToComponent(MovingComponent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

	UFUNCTION()
	void AttachChildsToComponent(USceneComponent SceneComponent)
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto Actor : AttachedActors)
		{
			Actor.AttachToComponent(SceneComponent, AttachmentRule = EAttachmentRule::KeepWorld);
		}
	}
}