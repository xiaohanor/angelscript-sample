
#if EDITOR
class UContextualMovesTargetableVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UContextualMovesTargetableComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		auto Comp = Cast<UContextualMovesTargetableComponent>(Component);
		if (Comp == nullptr)
			return;

		if (Comp.bRestrictToForwardVector)
		{
			DrawArc(
				Comp.WorldLocation, Comp.ForwardVectorCutOffAngle * 2.0, Comp.ActivationRange,
				-Comp.ForwardVector, FLinearColor::Green, 4.0, Comp.UpVector
			);

			if (Comp.bRestrictVerticalAngle)
			{
				DrawArc(
					Comp.WorldLocation, Comp.VerticalCutOffAngle * 2, Comp.ActivationRange,
					-Comp.ForwardVector, FLinearColor::LucBlue, 4.0, Comp.RightVector
				);
			}
		}
		else if (Comp.bRestrictVerticalAngle)
		{

			DrawArc(
				Comp.WorldLocation, Comp.VerticalCutOffAngle * 2, Comp.ActivationRange,
				-Comp.ForwardVector, FLinearColor::LucBlue, 4.0, Comp.RightVector
			);
			DrawArc(
				Comp.WorldLocation, Comp.VerticalCutOffAngle * 2, Comp.ActivationRange,
				Comp.ForwardVector, FLinearColor::LucBlue, 4.0, Comp.RightVector
			);
		}
    }
}
#endif
