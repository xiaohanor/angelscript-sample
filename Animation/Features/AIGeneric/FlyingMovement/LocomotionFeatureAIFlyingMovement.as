
struct FLocomotionFeatureAIFlyingMovementData
{
	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData MovementBS;

	UPROPERTY(Category = "Aiming")
	FHazePlayBlendSpaceData AimBS;
}

class ULocomotionFeatureAIFlyingMovement : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::Flying;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIFlyingMovementData FeatureData;
}
