UCLASS(NotBlueprintable)
class UJetskiSplineIgnoreRubberBandingComponent : UAlongSplineComponent
{
#if EDITOR
	default EditorColor = FLinearColor::Purple;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Jetski Ignore Rubber Banding")
	bool bIgnoreRubberBanding = true;
};

#if EDITOR
class UJetskiSplineIgnoreRubberBandingComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UJetskiSplineIgnoreRubberBandingComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto IgnoreRubberBandingComp = Cast<UJetskiSplineIgnoreRubberBandingComponent>(Component);
		if(IgnoreRubberBandingComp == nullptr)
			return;
		
		const FString Text = IgnoreRubberBandingComp.bIgnoreRubberBanding ? "Rubber Banding Ignored" : "Rubber Banding Active";
		const FLinearColor Color = IgnoreRubberBandingComp.bIgnoreRubberBanding ? FLinearColor::Red : FLinearColor::Green;
		DrawWorldString(Text, IgnoreRubberBandingComp.WorldLocation, Color, 1, -1, false, true);
	}
}
#endif