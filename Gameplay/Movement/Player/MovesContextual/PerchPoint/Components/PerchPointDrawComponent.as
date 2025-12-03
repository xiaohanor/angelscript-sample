
class UPerchPointDrawComponent : UHazeEditorRenderedComponent
{
	default bIsEditorOnly = true;
	default SetHiddenInGame(true);

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR

		UPerchPointComponent Comp = Owner.GetComponentByClass(UPerchPointComponent);
		if(Comp == nullptr)
			return;

		SetActorHitProxy();

		if(Comp.bAlwaysVisualizeRanges)
		{
			if (Comp.bAllowAutoJumpTo && Comp.ActivationRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange, FLinearColor(0.0, 0.4, 0.0), 2.0);

			if (Comp.bAllowGrappleToPoint && Comp.AdditionalGrappleRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalGrappleRange, FLinearColor::Blue, 2.0);

			if(Comp.bAllowGrappleToPoint && Comp.ActivationRange > 0.0 && Comp.AdditionalVisibleRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalGrappleRange + Comp.AdditionalVisibleRange, FLinearColor::Purple, 2.0);

			if(Comp.MinimumRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.MinimumRange, FLinearColor::Red, Thickness = 2.0);
		}

		if(Comp.bShowWorldUpCutoff && Comp.bShouldValidateWorldUp)
		{
			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.UpVectorCutOffAngle, Direction = Comp.UpVector, Normal = Owner.ActorForwardVector, Color = FLinearColor::Red, Thickness = 2.5);
			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.UpVectorCutOffAngle, Direction = Comp.UpVector, Normal = Owner.ActorRightVector, Color = FLinearColor::Red, Thickness = 2.5);
			DrawArrow(Comp.WorldLocation + Comp.UpVector * 100, Comp.WorldLocation + Comp.UpVector * 125.0, Color = FLinearColor::Red, Thickness = 2.5);
		}

#endif
	}
}