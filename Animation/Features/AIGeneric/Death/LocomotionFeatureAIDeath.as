
struct FLocomotionFeatureAIDeathData
{
    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData Default;

  

    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathKnockback;

    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathLeft;

    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathPushback;

    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathSlipback;

    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathTwistRight;

    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathTwistLeft;

     UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathFlungBack;

    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathAirEnter;

    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathAirMh;

    UPROPERTY(BlueprintReadOnly, Category = "AIDeath")
    FHazePlaySequenceData DeathAirEnd;
}

class ULocomotionFeatureAIDeath : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAITags::Death;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIDeathData FeatureData;
}