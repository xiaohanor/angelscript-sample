/**
 * If this component is placed on an actor with a DarkPortalTargetComponent, the portal
 */
class UDarkPortalAutoPlacementComponent : USceneComponent
{
	/**
	 * Only do auto-placement if the original surface normal is within this angle of the auto placement normal
	 */
	UPROPERTY(EditAnywhere)
	float MaximumAutoPlacementSurfaceAngle = 90.0;
	
	/**
	 * Only do auto-placement if it would originally be placed inside this shape.
	 */
	UPROPERTY(EditAnywhere)
	bool bOnlyWhenPlacedInShape = false;

	UPROPERTY(EditAnywhere)
	bool bSpecialCasePullBecauseActorCanRotate = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bOnlyWhenPlacedInShape", EditConditionHides))
	FHazeShapeSettings PlacementShape = FHazeShapeSettings::MakeBox(FVector(100));
};

#if EDITOR
class UDarkPortalAutoPlacementComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UDarkPortalAutoPlacementComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UDarkPortalAutoPlacementComponent Comp = Cast<UDarkPortalAutoPlacementComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		DrawArrow(Comp.WorldLocation, Comp.WorldLocation + Comp.ForwardVector * 200.0,
			FLinearColor::Red, 10.0, 5.0);

		if (Comp.bOnlyWhenPlacedInShape)
		{
			VisualizeShape(Comp.PlacementShape, Comp.WorldTransform, FLinearColor::Red, 5.0);
		}
    }   

    void VisualizeShape(FHazeShapeSettings Shape, FTransform Transform, FLinearColor Color, float Thickness)
    {
        FVector CenterPos = Transform.Location;
		FQuat WorldRotation = Transform.Rotation;
        FVector Scale = Transform.GetScale3D();

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