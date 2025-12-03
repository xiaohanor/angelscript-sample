
struct FLocomotionFeatureAIMovementData
{
    UPROPERTY(BlueprintReadOnly, Category = "Movement")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData JogStart;

	UPROPERTY(Category = "Movement")
	FHazePlayBlendSpaceData MovementBS;

	UPROPERTY(Category = "Movement")
	FHazePlaySequenceData JogStopEasy;
}

class ULocomotionFeatureAIMovement : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::Movement;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIMovementData FeatureData;
}