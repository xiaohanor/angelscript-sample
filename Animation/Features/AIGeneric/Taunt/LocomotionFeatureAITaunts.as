
struct FLocomotionFeatureAITauntsData
{
    UPROPERTY(BlueprintReadOnly, Category = "AITaunts")
    FHazePlaySequenceData SpotTarget;

    UPROPERTY(BlueprintReadOnly, Category = "AITaunts")
    FHazePlaySequenceData Tracking;

    UPROPERTY(BlueprintReadOnly, Category = "AITaunts")
    FHazePlaySequenceData Telegraph;

    UPROPERTY(BlueprintReadOnly, Category = "AITaunts")
    FHazePlaySequenceData IdleMH;
}

class ULocomotionFeatureAITaunts : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::Taunt;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAITauntsData FeatureData;
}