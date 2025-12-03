
struct FLocomotionFeatureAIShootingData
{
    UPROPERTY(BlueprintReadOnly, Category = "AIShooting")
    FHazePlaySequenceData SingleShot;

	UPROPERTY(Category = "AIShooting")
    FHazePlaySequenceData Reload;

	UPROPERTY(Category = "AIShooting")
    FHazePlaySequenceData IdleMH;
}

class ULocomotionFeatureAIShooting : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::Shooting;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIShootingData FeatureData;
}