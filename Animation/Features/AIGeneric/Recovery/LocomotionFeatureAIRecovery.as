
struct FLocomotionFeatureAIRecoveryData
{
    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData Rest;

    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData Duck;

    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData IdleMH;
}

class ULocomotionFeatureAIRecovery : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::Recovery;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIRecoveryData FeatureData;
}