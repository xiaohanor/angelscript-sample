
struct FLocomotionFeatureAIGravityWhipWallImpactData
{  
    UPROPERTY(BlueprintReadOnly, Category = "GravityWhipWallImpact")
    FHazePlaySequenceData ImpactStart;

    UPROPERTY(BlueprintReadOnly, Category = "GravityWhipWallImpact")
    FHazePlaySequenceData ImpactMh;

    UPROPERTY(BlueprintReadOnly, Category = "GravityWhipWallImpact")
    FHazePlaySequenceData ImpactRecover;

    UPROPERTY(BlueprintReadOnly, Category = "GravityWhipWallImpact")
    FHazePlaySequenceData Death;
}

class ULocomotionFeatureAIGravityWhipWallImpact : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAISkylineTags::GravityWhipWallImpact;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIGravityWhipWallImpactData FeatureData;
}