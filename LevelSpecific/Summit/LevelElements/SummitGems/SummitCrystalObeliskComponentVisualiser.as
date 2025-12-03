
#if EDITOR
class USummitCrystalObeliskComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USummitCrystalObeliskComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        USummitCrystalObeliskComponent Comp = Cast<USummitCrystalObeliskComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		SetRenderForeground(false);
        VisualizeShape(Comp, Comp.MetalZoneShapeSetting, FTransform::Identity, FLinearColor::Gray, 2.0);
		VisualizeConnections(Comp, FLinearColor::Red, 5);
    }   

    void VisualizeShape(USummitCrystalObeliskComponent Comp, FHazeShapeSettings Shape, FTransform Transform, FLinearColor Color, float Thickness)
    {
        FVector CenterPos = Comp.WorldTransform.TransformPosition(Transform.Location);
		FQuat WorldRotation = Comp.WorldTransform.TransformRotation(Transform.Rotation);
        FVector Scale = Transform.GetScale3D() * Comp.WorldScale;

        switch (Shape.Type)
        {
            case EHazeShapeType::Box:
                DrawWireBox(CenterPos, Scale * Shape.BoxExtents, WorldRotation, FLinearColor::Red, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Sphere:
                DrawWireSphere(CenterPos, Scale.Max * Shape.SphereRadius, FLinearColor::Red, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Capsule:
                DrawWireCapsule(CenterPos, Transform.Rotator(), FLinearColor::Red, Shape.CapsuleRadius * Scale.Max, Shape.CapsuleHalfHeight * Scale.Max, Thickness = Thickness, bScreenSpace = true);
            break;
			default : break;
        }
    }
	
	void VisualizeConnections(USummitCrystalObeliskComponent Comp, FLinearColor LineColor, float Thickness)
	{
		auto Owner = Cast<ASummitNightQueenGem>(Comp.Owner);

		if(Owner == nullptr)
			return;
		
		for(auto Metal : Owner.PoweringMetalPieces)
		{
			if(Metal == nullptr)
				continue;

			DrawLine(Comp.Owner.ActorLocation, Metal.ActorLocation, LineColor, Thickness);
		}
	}
} 
#endif