#if EDITOR
class UBounceKiteVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBounceKiteComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        ABounceKite Kite = Cast<ABounceKite>(Component.Owner);
        if (Kite == nullptr)
            return;

		UBounceKiteComponent BounceKiteComp = Cast<UBounceKiteComponent>(Component);
		DrawArrow(BounceKiteComp.WorldLocation, BounceKiteComp.WorldLocation + (FVector::UpVector * Kite.BounceHeight), FLinearColor::Purple, 50.0, 10.0);
    }
}
#endif