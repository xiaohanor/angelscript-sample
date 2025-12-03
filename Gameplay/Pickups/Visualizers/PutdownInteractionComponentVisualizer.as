#if EDITOR
class UPutdownInteractionComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPutdownInteractionComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UPutdownInteractionComponent PutdownInteractionComponent = Cast<UPutdownInteractionComponent>(Component);
		if (PutdownInteractionComponent == nullptr)
			return;

		UMaterialInterface MeshShiftPreviewMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Engine/EngineDebugMaterials/M_SimpleTranslucent.M_SimpleTranslucent"));

		SetHitProxy(n"PutdownInteraction", EVisualizerCursor::SlashedCircle);

		// Draw debug pickup mesh
		UStaticMesh PreviewMesh = PutdownInteractionComponent.PreviewMesh;
		if (PreviewMesh != nullptr)
		{
			FTransform WorldTransform = PutdownInteractionComponent.PickupSocketTransform * PutdownInteractionComponent.Owner.ActorTransform;
			DrawMeshWithMaterial(PreviewMesh, MeshShiftPreviewMaterial, WorldTransform.Location, WorldTransform.Rotation, WorldTransform.Scale3D);
		}

		SetRenderForeground(false);
        VisualizeShape(PutdownInteractionComponent, PutdownInteractionComponent.FocusShape, PutdownInteractionComponent.FocusShapeTransform, FLinearColor::Gray, 2.0);
        VisualizeShape(PutdownInteractionComponent, PutdownInteractionComponent.ActionShape, PutdownInteractionComponent.ActionShapeTransform, FLinearColor(0.2, 0.5, 0.2), 2.0);
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