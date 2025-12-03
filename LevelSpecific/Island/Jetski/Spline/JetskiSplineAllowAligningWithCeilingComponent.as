enum EJetskiSplineCustomAlignment
{
	Off,
	Walls,
	WallsAndCeilings,
};

UCLASS(NotBlueprintable)
class UJetskiSplineAllowAligningWithCeilingComponent : UAlongSplineComponent
{
#if EDITOR
	default EditorColor = FLinearColor::Green;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Jetski Align With Ceiling")
	bool bAllowAligningWithCeiling = true;
};

#if EDITOR
class UJetskiSplineAllowAligningWithCeilingComponentVisualizer : UAlongSplineComponentVisualizer
{
	default VisualizedClass = UJetskiSplineAllowAligningWithCeilingComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto AlignWithGroundComp = Cast<UJetskiSplineAllowAligningWithCeilingComponent>(Component);
		if(AlignWithGroundComp == nullptr)
			return;
		
		const FString Text = f"Align With Ceiling: {AlignWithGroundComp.bAllowAligningWithCeiling}";
		const FLinearColor Color = AlignWithGroundComp.bAllowAligningWithCeiling ? FLinearColor::Green : FLinearColor::Red;
		DrawWorldString(Text, AlignWithGroundComp.WorldLocation, Color, 1, -1, false, true);
	}
}
#endif