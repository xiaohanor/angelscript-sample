// Determine whether the capsule component contains a point
mixin bool IsPointInside(UHazeCapsuleCollisionComponent Capsule, FVector Point)
{
	return FHazeShapeSettings::MakeCapsule(
		Capsule.CapsuleRadius, Capsule.CapsuleHalfHeight
	).IsPointInside(Capsule.WorldTransform, Point);
}

// Determine whether the capsule component intersects a sphere
mixin bool IntersectsSphere(UHazeCapsuleCollisionComponent Capsule, FVector SphereOrigin, float SphereRadius)
{
	return Overlap::QueryShapeOverlap(
		Capsule.GetCollisionShape(),
		Capsule.WorldTransform,
		FCollisionShape::MakeSphere(SphereRadius),
		FTransform(SphereOrigin)
	);
}

// Determine whether the box component contains a point
mixin bool IsPointInside(UBoxComponent Box, FVector Point)
{
	return FHazeShapeSettings::MakeBox(
		Box.BoxExtent
	).IsPointInside(Box.WorldTransform, Point);
}

// Determine whether the box component intersects a sphere
mixin bool IntersectsSphere(UBoxComponent Box, FVector SphereOrigin, float SphereRadius)
{
	return Overlap::QueryShapeOverlap(
		Box.GetCollisionShape(),
		Box.WorldTransform,
		FCollisionShape::MakeSphere(SphereRadius),
		FTransform(SphereOrigin)
	);
}