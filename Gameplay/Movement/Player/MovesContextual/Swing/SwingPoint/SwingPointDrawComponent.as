class USwingPointDrawComponent : UHazeEditorRenderedComponent
{
	default bIsEditorOnly = true;
	default SetHiddenInGame(true);

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		USwingPointComponent Comp = Owner.GetComponentByClass(USwingPointComponent);
		if (Comp == nullptr)
			return;

		SetActorHitProxy();

		if(Comp.bAlwaysVisualizeRanges)
		{
			DrawWireSphere(Comp.WorldLocation, Comp.TetherLength + 82, FLinearColor::LucBlue, Thickness = 2.0, Segments = 12);
			DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange, FLinearColor::Blue, Thickness = 2.0, Segments = 12);	
			DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalVisibleRange, FLinearColor::Purple, 2.0, 12.0);

			if(Comp.MinimumRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.MinimumRange, FLinearColor::Red, 2.0, 12.0);
		}

		if(Comp.bShowWorldUpCutoff)
		{
			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.UpVectorCutOffAngle, Direction = Comp.UpVector, Normal = Owner.ActorForwardVector, Color = FLinearColor::Red, Thickness = 2.5);
			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.UpVectorCutOffAngle, Direction = Comp.UpVector, Normal = Owner.ActorRightVector, Color = FLinearColor::Red, Thickness = 2.5);
			DrawArrow(Comp.WorldLocation + Comp.UpVector * 100, Comp.WorldLocation + Comp.UpVector * 125.0, Color = FLinearColor::Red, Thickness = 2.5);
		}	
		
		ClearHitProxy();
#endif
	}
}