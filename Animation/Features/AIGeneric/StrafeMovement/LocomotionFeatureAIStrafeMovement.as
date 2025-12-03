
struct FLocomotionFeatureAIStrafeMovementData
{
	UPROPERTY(Category = "Movement|NotAiming")
	FHazePlayBlendSpaceData StartBS;

	UPROPERTY(Category = "Movement|NotAiming")
	FHazePlayBlendSpaceData MovementBS;

	UPROPERTY(Category = "Movement|NotAiming")
	FHazePlayBlendSpaceData StopBS;

	UPROPERTY(Category = "Movement|NotAiming")
	FHazePlayBlendSpaceData TurnInPlaceBS;
}

class ULocomotionFeatureAIStrafeMovement : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::StrafeMovement;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIStrafeMovementData FeatureData;
}
