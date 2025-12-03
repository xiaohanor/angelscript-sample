
struct FLocomotionFeatureAIFleeData
{
    UPROPERTY(BlueprintReadOnly, Category = "AIFlee")
    FHazePlayRndSequenceData StartFleeing;
}

class ULocomotionFeatureAIFlee : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::Flee;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIFleeData FeatureData;
}