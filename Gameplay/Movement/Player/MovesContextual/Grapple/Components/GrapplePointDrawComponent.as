
class UGrapplePointDrawComponent : UHazeEditorRenderedComponent
{
	default bIsEditorOnly = true;
	default SetHiddenInGame(true);

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
	
		UGrapplePointBaseComponent Comp = Owner.GetComponentByClass(UGrapplePointBaseComponent);
		if(Comp == nullptr)
			return;
	

		SetActorHitProxy();

		if(Comp.bAlwaysVisualizeRanges)
		{
			if (Comp.ActivationRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange, FLinearColor::Blue, 2.0);

			if (Comp.ActivationRange > 0.0 && Comp.AdditionalVisibleRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalVisibleRange, FLinearColor::Purple, 2.0);

			if (Comp.MinimumRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.MinimumRange, FLinearColor::Red, Thickness = 2.0);
		}

		if(Comp.bShowWorldUpCutoff && Comp.bShouldValidateWorldUp)
		{
			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.UpVectorCutOffAngle, Radius = 150, Direction = Comp.UpVector, Normal = Owner.ActorForwardVector, Color = FLinearColor::Red, Thickness = 2.5);
			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.UpVectorCutOffAngle, Radius = 150, Direction = Comp.UpVector, Normal = Owner.ActorRightVector, Color = FLinearColor::Red, Thickness = 2.5);
			DrawArrow(Comp.WorldLocation + Comp.UpVector * 150, Comp.WorldLocation + Comp.UpVector * 175.0, Color = FLinearColor::Red, Thickness = 2.5);
		}

		ClearHitProxy();

#endif
	}
};