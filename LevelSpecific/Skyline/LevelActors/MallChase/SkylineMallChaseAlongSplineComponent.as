#if EDITOR
/**
 * Helper for easily creating selectable visualizers along a spline
 */
class USkylineMallChaseAlongSplineComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = USkylineMallChaseAlongSplineComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto MallChaseComp = Cast<USkylineMallChaseAlongSplineComponent>(Component);

		if (MallChaseComp.ActorWithSkylineInteface == nullptr)
			return;

		DrawDashedLine(MallChaseComp.WorldLocation,  MallChaseComp.ActorWithSkylineInteface.ActorLocation, FLinearColor::Green, 10.0, 10.0, false, 40);
	}
}
#endif

class USkylineMallChaseAlongSplineComponent : UAlongSplineComponent
{
	UPROPERTY(EditInstanceOnly)
	AActor ActorWithSkylineInteface;

	void Activate()
	{
		auto InterfaceComp = USkylineInterfaceComponent::Get(ActorWithSkylineInteface);
		InterfaceComp.TriggerActivate();
	}
};