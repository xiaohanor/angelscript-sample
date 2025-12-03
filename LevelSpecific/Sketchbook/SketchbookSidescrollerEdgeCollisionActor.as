class ASketchbookSidescrollerEdgeCollisionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Collision;
	default Collision.CollisionProfileName = n"BlockOnlyPlayerCharacter";
	default Collision.RemoveTag(ComponentTags::InheritHorizontalMovementIfGround);
	default Collision.RemoveTag(ComponentTags::Walkable);
	default Collision.RemoveTag(ComponentTags::LedgeClimbable);
	default Collision.RemoveTag(ComponentTags::DarkPortalPlaceable);
	
	UPROPERTY(DefaultComponent, Attach = Collision)
	UMoveIntoPlayerShapeComponent MoveIntoPlayerShapeComp;

	void SetBoxExtent(FVector BoxExtents) property
	{
		Collision.BoxExtent = BoxExtents;
		MoveIntoPlayerShapeComp.Shape.BoxExtents = BoxExtents;
	}
}