
class UPlayerLookAtTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UPlayerLookAtTriggerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		UPlayerLookAtTriggerComponent LookAtComp = Cast<UPlayerLookAtTriggerComponent>(Component);
		if (LookAtComp == nullptr)
			return;		

		if (LookAtComp.TriggerVolume != nullptr)
			DrawDashedLine(LookAtComp.WorldLocation, LookAtComp.TriggerVolume.ActorLocation, FLinearColor::Yellow, 10.0);
		
		// Range
		FVector ViewLoc = Editor::GetEditorViewLocation();
		FLinearColor RangeColor = (LookAtComp.WorldLocation.IsWithinDist(ViewLoc, LookAtComp.Range)) ? FLinearColor::Green : FLinearColor::Red;
		DrawWireSphere(LookAtComp.WorldLocation, LookAtComp.Range, RangeColor, 10.0, 12);
		
		// View center fraction
		float DrawDist = 100.0;
		FRotator ViewRot = Editor::GetEditorViewRotation();
		FVector ViewFwd = ViewRot.Vector();
		FVector ViewRight = FRotator(0.0, 90.0, 0.0).Compose(ViewRot).Vector();
		FVector2D ViewRes = Editor::GetEditorViewResolution();
		float AspectRatio = ViewRes.X / ViewRes.Y;
		if (Math::IsNaN(AspectRatio))
			AspectRatio = 16.0 / 9.0;
		float VerticalFOV = Math::Clamp(Editor::GetEditorViewFOV(), 5.0, 179.0);
		float HorizontalFOV = Math::Clamp(Math::RadiansToDegrees(2.0 * Math::Atan(Math::Tan(Math::DegreesToRadians(VerticalFOV * 0.5)) * AspectRatio)), 5.0, 179.0);
		float Height = DrawDist * Math::Tan(Math::DegreesToRadians(VerticalFOV * 0.5));
		float Width = DrawDist * Math::Tan(Math::DegreesToRadians(HorizontalFOV * 0.5));
		FVector DrawPlaneCenter = ViewLoc + ViewFwd * DrawDist;

		// Are we looking close enough?
		bool bLookingAt = false;
		if (ViewFwd.DotProduct(LookAtComp.WorldLocation - ViewLoc) > 0.0) // TODO: This is incorrect if view > 90
		{
			FVector DrawPlaneVec = FTransform(ViewRot, DrawPlaneCenter).InverseTransformPosition(Math::LinePlaneIntersection(ViewLoc, LookAtComp.WorldLocation, DrawPlaneCenter, ViewFwd));
			FVector2D DrawPlaneFraction = FVector2D(DrawPlaneVec.Y / Width, DrawPlaneVec.Z / Height);
			if (DrawPlaneFraction.SizeSquared() < Math::Square(LookAtComp.ViewCenterFraction))
				bLookingAt = true; 

			//FVector Origin = DrawPlaneCenter;
			FVector Origin = Math::LinePlaneIntersection(LookAtComp.WorldLocation, ViewLoc, DrawPlaneCenter, ViewFwd);
			FLinearColor ViewColor = bLookingAt ?  FLinearColor::Green : FLinearColor::Red;// FLinearColor(1.0, 0.5, 0.0);
			DrawEllipse(Origin, FVector2D(Width, Height) * LookAtComp.ViewCenterFraction, ViewColor, 0.2, 0.0, ViewFwd, ViewRight);
		}
		DrawPoint(DrawPlaneCenter, FLinearColor::Purple, 8.0);
	}
};