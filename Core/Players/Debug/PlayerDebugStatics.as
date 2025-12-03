UFUNCTION(Category = "Debug")
mixin void DebugDrawCollisionCapsule(AHazePlayerCharacter Player, float Duration = 0.0, FLinearColor Color = FLinearColor::DPink)
{
	UHazeMovementComponent MovementComponent = UHazeMovementComponent::Get(Player);
	if (MovementComponent != nullptr)
	{
		FHazeTraceShape CollisionShape = MovementComponent.CollisionShape;
		if (CollisionShape.IsBox())
		{
			Debug::DrawDebugBox(MovementComponent.ShapeComponent.WorldLocation, MovementComponent.CollisionShape.Shape.Box, MovementComponent.ShapeComponent.WorldRotation, Color, 3, Duration);
		}

		if (CollisionShape.IsCapsule())
		{
			Debug::DrawDebugCapsule(MovementComponent.ShapeComponent.WorldLocation, MovementComponent.CollisionShape.Shape.CapsuleHalfHeight, MovementComponent.CollisionShape.Shape.CapsuleRadius, MovementComponent.ShapeComponent.WorldRotation, Color, 3, Duration);
		}

		if (CollisionShape.IsSphere())
		{
			Debug::DrawDebugSphere(MovementComponent.ShapeComponent.WorldLocation, MovementComponent.CollisionShape.Shape.SphereRadius, 12,  Color, 3, Duration);
		}
	}
}