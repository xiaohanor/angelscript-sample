
class APlayerInheritMovementZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UPlayerInheritMovementComponent InheritMovementComp;
	default InheritMovementComp.FollowBehavior = EMovementFollowComponentType::ResolveCollision;
	default InheritMovementComp.FollowType = EPlayerInheritMovementFollowType::FollowImpactedMesh;
	default InheritMovementComp.ActivateType = EPlayerInheritMovementActivationType::InsideShapeAfterGroundImpact;
	default InheritMovementComp.DeactivationType = EPlayerInheritMovementDeactivationType::OutsideShapeAfterAnyImpact;
	default InheritMovementComp.Shape.Type = EHazeShapeType::Box;
	default InheritMovementComp.Shape.BoxExtents = FVector(800, 800, 800);
	default InheritMovementComp.ShapeColor = FLinearColor::Green;
	default InheritMovementComp.EditorLineThickness = 10.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "S_NavP";
#endif
}