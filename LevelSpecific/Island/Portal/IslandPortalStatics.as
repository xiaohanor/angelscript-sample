namespace IslandPortal
{
	FVector TransformVectorToPortalSpace(AIslandPortal OriginPortal, AIslandPortal DestinationPortal, FVector Vector)	
	{
		// Transform vector into the local space of the origin portal, this is rotated 180 degrees so we come out of the front face on the other portal
		FTransform OriginTransform = FTransform(FRotator::MakeFromXZ(-OriginPortal.ActorForwardVector, OriginPortal.ActorUpVector), OriginPortal.ActorLocation, OriginPortal.ActorScale3D);
		FVector LocalVector = OriginTransform.InverseTransformVectorNoScale(Vector);

		// Transform the local vector into world space using the destination portal's transform
		FTransform DestinationTransform = DestinationPortal.ActorTransform;
		FVector FinalVector = DestinationTransform.TransformVectorNoScale(LocalVector);
		return FinalVector;
	}

	FRotator TransformRotationToPortalSpace(AIslandPortal OriginPortal, AIslandPortal DestinationPortal, FRotator Rotation)
	{
		// Transform rotation into the local space of the origin portal, this is rotated 180 degrees so we come out of the front face on the other portal
		FTransform OriginTransform = FTransform(FRotator::MakeFromXZ(-OriginPortal.ActorForwardVector, OriginPortal.ActorUpVector), OriginPortal.ActorLocation, OriginPortal.ActorScale3D);
		FRotator LocalRotation = OriginTransform.InverseTransformRotation(Rotation);

		// Transform the local rotation into world space using the destination portal's transform
		FTransform DestinationTransform = DestinationPortal.ActorTransform;
		FRotator FinalRotation = DestinationTransform.TransformRotation(LocalRotation);
		return FinalRotation;
	}

	FVector TransformPositionToPortalSpace(AIslandPortal OriginPortal, AIslandPortal DestinationPortal, FVector Position)
	{
		// Transform rotation into the local space of the origin portal, this is rotated 180 degrees so we come out of the front face on the other portal
		FTransform OriginTransform = FTransform(FRotator::MakeFromXZ(-OriginPortal.ActorForwardVector, OriginPortal.ActorUpVector), OriginPortal.ActorLocation, OriginPortal.ActorScale3D);
		FVector LocalPosition = OriginTransform.InverseTransformPositionNoScale(Position);

		// Transform the local rotation into world space using the destination portal's transform
		FTransform DestinationTransform = DestinationPortal.ActorTransform;
		FVector FinalPosition = DestinationTransform.TransformPositionNoScale(LocalPosition);
		return FinalPosition;
	}
}