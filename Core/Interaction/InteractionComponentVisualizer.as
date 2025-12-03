
#if EDITOR
class UInteractionComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UInteractionComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UInteractionComponent Comp = Cast<UInteractionComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		SetRenderForeground(false);
        VisualizeShape(Comp, Comp.FocusShape, Comp.FocusShapeTransform, FLinearColor::Gray, 2.0);
        VisualizeShape(Comp, Comp.ActionShape, Comp.ActionShapeTransform, FLinearColor(0.2, 0.5, 0.2), 2.0);
    }   

    void VisualizeShape(UInteractionComponent Comp, FHazeShapeSettings Shape, FTransform Transform, FLinearColor Color, float Thickness)
    {
        FVector CenterPos = Comp.WorldTransform.TransformPosition(Transform.Location);
		FQuat WorldRotation = Comp.WorldTransform.TransformRotation(Transform.Rotation);
        FVector Scale = Transform.GetScale3D() * Comp.WorldScale;

        switch (Shape.Type)
        {
            case EHazeShapeType::Box:
                DrawWireBox(CenterPos, Scale * Shape.BoxExtents, WorldRotation, Color, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Sphere:
                DrawWireSphere(CenterPos, Scale.Max * Shape.SphereRadius, Color, Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::Capsule:
                DrawWireCapsule(CenterPos, Transform.Rotator(), Color, Shape.CapsuleRadius * Scale.Max, Shape.CapsuleHalfHeight * Scale.Max, Thickness = Thickness, bScreenSpace = true);
            break;
            case EHazeShapeType::None:
            break;
        }
    }
} 
#endif