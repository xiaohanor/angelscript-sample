
struct FLocomotionFeatureAIGravityWhippableData
{
    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData GrabbedStart1;

	UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData GrabbedStart2;

    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData GrabbedMh1;

	UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData GrabbedMh2;

    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData GrabbedRelease;

	UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData GrabbedReleaseFallMH;

    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData GrabbedLand;

    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData ThrownStart;

    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData ThrownMh;

    UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData IdleMH;

	UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData Stumble;

	UPROPERTY(BlueprintReadOnly, Category = "AIRecovery")
    FHazePlaySequenceData Flinch;
}

class ULocomotionFeatureAIGravityWhippable : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAISkylineTags::GravityWhippable;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIGravityWhippableData FeatureData;
}