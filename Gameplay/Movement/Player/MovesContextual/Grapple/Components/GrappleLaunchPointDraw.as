class UGrappleLaunchPointDrawComponent : UHazeEditorRenderedComponent
{
	default SetHiddenInGame(true);

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		UGrappleLaunchPointComponent Comp = Owner.GetComponentByClass(UGrappleLaunchPointComponent);
		if (Comp == nullptr)
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

		if(Comp.bShowWorldUpCutoff)
		{
			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.UpVectorCutOffAngle, Radius = 150, Direction = Comp.UpVector, Normal = Owner.ActorForwardVector, Color = FLinearColor::Red, Thickness = 2.5);
			DrawArc(Comp.WorldLocation, Angle = 2 * Comp.UpVectorCutOffAngle, Radius = 150, Direction = Comp.UpVector, Normal = Owner.ActorRightVector, Color = FLinearColor::Red, Thickness = 2.5);
			DrawArrow(Comp.WorldLocation + Comp.UpVector * 150, Comp.WorldLocation + Comp.UpVector * 175.0, Color = FLinearColor::Red, Thickness = 2.5);
		}	
		
		ClearHitProxy();

        // if (!Comp.bUsePreferedDirection)
        //     return;

		// SetActorHitProxy();

		// FVector WorldLaunchDirection = Comp.Owner.ActorTransform.TransformPosition(Comp.PreferedDirection);
		// WorldLaunchDirection = WorldLaunchDirection - Comp.Owner.ActorLocation;
		// WorldLaunchDirection = WorldLaunchDirection.GetSafeNormal();
		// DrawArrow(Comp.WorldLocation + (FVector::UpVector * Comp.LaunchHeightOffset),Comp.WorldLocation + (FVector::UpVector * Comp.LaunchHeightOffset) + (WorldLaunchDirection * 250) , FLinearColor::Red, 10.0, 8.0);
		// DrawCone(Comp.WorldLocation + (FVector::UpVector * Comp.LaunchHeightOffset), -WorldLaunchDirection, Comp.ActivationRange, Comp.AcceptanceDegrees, Comp.AcceptanceDegrees, 12, FLinearColor::Green);

		// ClearHitProxy();		
#endif
	}
}