
delegate void FOnMoveToEnded(AHazeActor Actor);

enum EMoveToType
{
	// Don't move at all
	NoMovement,
	// Smooth teleport to the point (completes instantly)
	SmoothTeleport,
	// Snap teleport the point (completes instantly)
	SnapTeleport,
	// The player does an animation to the point depending on where they currently are relative to it
	AnimateTo,
	// The player does a jump to the point
	JumpTo,
};

enum EMoveToPosition
{
	// Move to the destination point and its rotation
	Destination,
	// Move to a specific distance from the destination point
	DistanceFromDestination,
	// Move to within a specified range from the destination point
	RangeFromDestination,
};

struct FMoveToParams
{
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement")
	EMoveToType Type = EMoveToType::SmoothTeleport;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement", Meta = (EditCondition = "Type != EMoveToType::NoMovement", EditConditionHides))
	EMoveToPosition Position = EMoveToPosition::Destination;

	// Distance from the destination position to move to
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement", Meta = (EditCondition = "Position == EMoveToPosition::DistanceFromDestination", EditConditionHides))
	float Distance = 100.0;

	// Minimum distance from the destination position to move to
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement", Meta = (EditCondition = "Position == EMoveToPosition::RangeFromDestination", EditConditionHides))
	float MinimumDistance = 0.0;

	// Maximum distance from the destination position to move to
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement", Meta = (EditCondition = "Position == EMoveToPosition::RangeFromDestination", EditConditionHides))
	float MaximumDistance = 100.0;

	// Whether to rotate to face the destination, rather than copying the destination's rotation
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement", Meta = (EditCondition = "Position == EMoveToPosition::RangeFromDestination || Position == EMoveToPosition::DistanceFromDestination", EditConditionHides))
	bool bFaceTowardsDestination = true;

	// Additional height for the player to jump for JumpTos
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Movement", Meta = (EditCondition = "Type == EMoveToType::JumpTo", EditConditionHides))
	float JumpAdditionalHeight = 120.0;

	// Whether these settings describe any movement at all
	bool HasMovement() const
	{
		return Type != EMoveToType::NoMovement;
	}
};

namespace FMoveToParams
{

/**
 * Create movement settings that are disabled and do not move the player.
 */
FMoveToParams NoMovement()
{
	FMoveToParams Params;
	Params.Type = EMoveToType::NoMovement;
	return Params;
}

/**
 * Create movement settings for a smooth teleport.
 * Smooth teleports instantly teleport the actor to the target position, but the mesh lerps in over a short period.
 */
FMoveToParams SmoothTeleport()
{
	FMoveToParams Params;
	Params.Type = EMoveToType::SmoothTeleport;
	return Params;
}

/**
 * Create movement settings for a snap teleport.
 * Smooth teleports instantly teleport the actor to the target position.
 */
FMoveToParams SnapTeleport()
{
	FMoveToParams Params;
	Params.Type = EMoveToType::SnapTeleport;
	return Params;
}

/**
 * Create movement settings for an AnimateTo.
 * The player will do an animation to the point depending on their current relative position.
 */
FMoveToParams AnimateTo()
{
	FMoveToParams Params;
	Params.Type = EMoveToType::AnimateTo;
	return Params;
}

}

struct FMoveToDestination
{
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	FTransform Transform;
	UPROPERTY(EditAnywhere, BlueprintReadWrite)
	USceneComponent Component;

	FMoveToDestination() {}

	FMoveToDestination(AActor DestinationActor, FTransform RelativeTransform = FTransform::Identity)
	{
		Transform = RelativeTransform;
		Component = DestinationActor.RootComponent;
	}

	FMoveToDestination(USceneComponent DestinationComponent, FTransform RelativeTransform = FTransform::Identity)
	{
		Transform = RelativeTransform;
		Component = DestinationComponent;
	}

	FMoveToDestination(FTransform DestinationTransform)
	{
		Transform = DestinationTransform;
		Component = nullptr;
	}

	FMoveToDestination(FVector DestinationLocation, FRotator DestinationRotation = FRotator::ZeroRotator)
	{
		Transform = FTransform(DestinationRotation, DestinationLocation);
		Component = nullptr;
	}

	FTransform CalculateDestination(FTransform OriginalTransform, FMoveToParams Params) const
	{
		FTransform Target;
		if (Component != nullptr)
			Target = FTransform::ApplyRelative(Component.WorldTransform, Transform);
		else
			Target = Transform;
		// MoveTos can never change the player's scale!
		Target.Scale3D = FVector::OneVector;

		if (Params.Position == EMoveToPosition::DistanceFromDestination)
		{
			FVector TowardsPoint = Target.Location - OriginalTransform.Location;
			TowardsPoint = TowardsPoint.ConstrainToPlane(OriginalTransform.Rotation.UpVector).GetSafeNormal();

			if (TowardsPoint.IsNearlyZero())
				TowardsPoint = OriginalTransform.Rotation.ForwardVector;

			Target.Location = Target.Location - (TowardsPoint * Params.Distance);
			if (Params.bFaceTowardsDestination)
				Target.Rotation = FQuat::MakeFromXZ(TowardsPoint, OriginalTransform.Rotation.UpVector);
		}
		else if (Params.Position == EMoveToPosition::RangeFromDestination)
		{
			FVector TowardsPoint = Target.Location - OriginalTransform.Location;
			TowardsPoint = TowardsPoint.ConstrainToPlane(OriginalTransform.Rotation.UpVector);

			float OriginalDistance = TowardsPoint.Size();
			if (OriginalDistance > 0)
				TowardsPoint /= OriginalDistance;
			else
				TowardsPoint = OriginalTransform.Rotation.ForwardVector;

			float TargetDistance = Math::Clamp(OriginalDistance, Params.MinimumDistance, Params.MaximumDistance);
			Target.Location = Target.Location - (TowardsPoint * TargetDistance);
			if (Params.bFaceTowardsDestination)
				Target.Rotation = FQuat::MakeFromXZ(TowardsPoint, OriginalTransform.Rotation.UpVector);
		}

		return Target;
	}
};