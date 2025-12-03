class UTeamLazyTriggerShapeComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UTeamLazyTriggerShapeComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UTeamLazyTriggerShapeComponent TriggerComp = Cast<UTeamLazyTriggerShapeComponent>(Component);
        if (!ensure((TriggerComp != nullptr) && (TriggerComp.GetOwner() != nullptr)))
            return;

		switch (TriggerComp.Shape.Type)
		{
			case EHazeShapeType::Box:
				DrawWireBox(
					TriggerComp.WorldLocation,
					TriggerComp.Shape.BoxExtents,
					TriggerComp.ComponentQuat,
					TriggerComp.VisualizeColor,
					TriggerComp.EditorLineThickness
				);
			break;
			case EHazeShapeType::Sphere:
				DrawWireSphere(
					TriggerComp.WorldLocation,
					TriggerComp.Shape.SphereRadius,
					TriggerComp.VisualizeColor,
					TriggerComp.EditorLineThickness
				);
			break;
			case EHazeShapeType::Capsule:
				DrawWireCapsule(
					TriggerComp.WorldLocation,
					TriggerComp.WorldRotation,
					TriggerComp.VisualizeColor,
					TriggerComp.Shape.CapsuleRadius,
					TriggerComp.Shape.CapsuleHalfHeight,
					16, 
					TriggerComp.EditorLineThickness
				);
			break;
			case EHazeShapeType::None:
			break;
		}
	}
}
