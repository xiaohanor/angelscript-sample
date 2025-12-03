
class UFallTowardSplineZoneVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

#if EDITOR
class UFallTowardSplineZoneVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UFallTowardSplineZoneVisualizerComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent ActorComponent)
    {
        auto Component = Cast<UFallTowardSplineZoneVisualizerComponent>(ActorComponent);
		
		// happens on teardown on the dummy component
		if(Component == nullptr)
			return;
		
		auto Zone = Cast<AFallTowardSplineZone>(Component.GetOwner());
        if (Zone == nullptr)
            return;

		if(Zone.GuideSpline == nullptr)
			return;
		
		FVector ViewLocation = EditorViewLocation;
		ViewLocation += EditorViewRotation.ForwardVector * 300;
		
		auto SplinePositon = Zone.GuideSpline.Spline.GetClosestSplinePositionToWorldLocation(ViewLocation);
		DrawCircle(SplinePositon.WorldLocation, Zone.GuideRadius, Normal = SplinePositon.WorldForwardVector);

		FRotator SplineRotation = SplinePositon.WorldRotation.Rotator();
		SplineRotation.Roll = Time::RealTimeSeconds * 10;
		DrawArrow(SplinePositon.WorldLocation + (SplineRotation.UpVector * Zone.GuideRadius), SplinePositon.WorldLocation);
	}

}
#endif