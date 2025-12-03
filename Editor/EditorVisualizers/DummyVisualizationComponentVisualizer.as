class UDummyVisualizationComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UDummyVisualizationComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UDummyVisualizationComponent Comp = Cast<UDummyVisualizationComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		FVector Origin; 
		if (Comp.ConnectionBase != nullptr) 
			Origin = Comp.ConnectionBase.WorldTransform.TransformPosition(Comp.ConnectionBaseOffset); 
		else
			Origin = Comp.Owner.ActorTransform.TransformPosition(Comp.ConnectionBaseOffset);

		for (AActor ConnectedActor : Comp.ConnectedActors)
		{
			if (ConnectedActor != nullptr)
				DrawDashedLine(Origin, ConnectedActor.ActorLocation, Comp.Color, Comp.DashSize, Comp.Thickness);
		}
		FTransform OwnerTransform = Comp.Owner.ActorTransform;
		for (const FVector& Loc : Comp.ConnectedLocalLocations)
		{
			DrawDashedLine(Origin, OwnerTransform.TransformPosition(Loc), Comp.Color, Comp.DashSize, Comp.Thickness);
		}

		for (FDummyVisualizationSphere Sphere : Comp.Spheres)
		{
		 	DrawWireSphere(Sphere.CenterComp.WorldLocation, Sphere.Radius, Comp.Color, Sphere.Thickness, Sphere.Segments);
		}

		for (FDummyVisualizationCylinder Cylinder : Comp.Cylinders)
		{
			FRotator Rot = Cylinder.CenterComp.WorldRotation;
		 	DrawWireCylinder(Cylinder.CenterComp.WorldLocation + Rot.RotateVector(Cylinder.Offset), Rot, Comp.Color, Cylinder.Radius, Cylinder.HalfHeight, Cylinder.Segments, Cylinder.Thickness);
		}
    }   
} 

