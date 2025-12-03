
struct FLocomotionFeatureAITeleporterData
{
	UPROPERTY(Category = "AITeleporter")
    FHazePlaySequenceData IdleMH;

    UPROPERTY(Category = "AITeleporter")
    FHazePlaySequenceData TeleportChaseDisappear;

    UPROPERTY(Category = "AITeleporter")
    FHazePlaySequenceData TeleportChaseReappear;

    UPROPERTY(Category = "AITeleporter")
    FHazePlaySequenceData TeleportRetreatDisappear;

    UPROPERTY(Category = "AITeleporter")
    FHazePlaySequenceData TeleportRetreatReappear;
}

class ULocomotionFeatureAITeleporter : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::Teleporter;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAITeleporterData FeatureData;
}