class UScenepointComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UScenepointComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
#if EDITOR
        UScenepointComponent Scenepoint = Cast<UScenepointComponent>(Component);
        if (!ensure((Scenepoint != nullptr) && (Scenepoint.Owner != nullptr)))
            return;
				
		FLinearColor Color = FLinearColor::Green;
		UArrowComponent Arrow = UArrowComponent::Get(Scenepoint.Owner);
		if (Arrow != nullptr)
			Color = Arrow.ArrowFColor.ReinterpretAsLinear();
		DrawWireSphere(Scenepoint.WorldLocation, Scenepoint.Radius, Color * 0.5, Scenepoint.Radius * 0.01);
#endif
	}
}
