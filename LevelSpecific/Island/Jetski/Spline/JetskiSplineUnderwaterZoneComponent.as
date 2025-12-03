UCLASS(NotBlueprintable)
class UJetskiSplineUnderwaterZoneComponent : UAlongSplineComponent
{
#if EDITOR
	default EditorColor = FLinearColor::Blue;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Jetski Underwater Zone")
	bool bForceUnderwater = true;
};

#if EDITOR
class UJetskiSplineUnderwaterZoneComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UJetskiSplineUnderwaterZoneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto UnderwaterZoneComp = Cast<UJetskiSplineUnderwaterZoneComponent>(Component);
		if(UnderwaterZoneComp == nullptr)
			return;
		
		const FString Text = UnderwaterZoneComp.bForceUnderwater ? f"Force Underwater" : "Not Underwater";
		const FLinearColor Color = UnderwaterZoneComp.bForceUnderwater ? FLinearColor::Blue : FLinearColor::Red;
		DrawWorldString(Text, UnderwaterZoneComp.WorldLocation, Color, 1, -1, false, true);
	}
}
#endif