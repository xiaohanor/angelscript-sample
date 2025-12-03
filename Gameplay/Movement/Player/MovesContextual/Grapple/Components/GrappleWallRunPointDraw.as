class UGrappleWallRunPointDrawComponent : UHazeEditorRenderedComponent
{
	default SetHiddenInGame(true);

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		UGrappleWallrunPointComponent Comp = Owner.GetComponentByClass(UGrappleWallrunPointComponent);
		if (Comp == nullptr)
			return;

		SetActorHitProxy();
		
		FHazeTraceSettings WallTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		WallTrace.UseLine();

		//Trace Distance at the time of writing this was 80 - PlayerCapsuleRadius = 48
		FHitResult WallTraceHit = WallTrace.QueryTraceSingle(Comp.WorldLocation, Comp.WorldLocation + (Comp.ForwardVector * 48));
		
		if(!WallTraceHit.bBlockingHit || WallTraceHit.bStartPenetrating)
			DrawArrow(Comp.WorldLocation - Comp.ForwardVector * 100.0, Comp.WorldLocation, FLinearColor::Red, 10.0, 2.0);
		else
			DrawArrow(Comp.WorldLocation - Comp.ForwardVector * 100.0, Comp.WorldLocation, FLinearColor::Green, 10.0, 2.0);

		ClearHitProxy();
		
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
}