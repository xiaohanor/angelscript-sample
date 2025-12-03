UCLASS(NotBlueprintable)
class UJetskiSplineForceThrottleComponent : UAlongSplineComponent
{
#if EDITOR
	default EditorColor = FLinearColor::Yellow;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Jetski Force Throttle")
	bool bForceThrottle = true;

	UPROPERTY(EditInstanceOnly, Category = "Jetski Force Throttle", Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float ForcedThrottle = 1.0;
};

#if EDITOR
class UJetskiSplineForceThrottleComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UJetskiSplineForceThrottleComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto ForceThrottleComp = Cast<UJetskiSplineForceThrottleComponent>(Component);
		if(ForceThrottleComp == nullptr)
			return;
		
		const FString Text = ForceThrottleComp.bForceThrottle ? f"Force Throttle: {ForceThrottleComp.ForcedThrottle}" : "No Forced Throttle";
		const FLinearColor Color = ForceThrottleComp.bForceThrottle ? FLinearColor::Green : FLinearColor::Red;
		DrawWorldString(Text, ForceThrottleComp.WorldLocation, Color, 1, -1, false, true);
	}
}
#endif