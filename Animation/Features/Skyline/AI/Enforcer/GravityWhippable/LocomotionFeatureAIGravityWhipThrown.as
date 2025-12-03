
struct FLocomotionFeatureAIGravityWhipThrownData
{  
    UPROPERTY(BlueprintReadOnly, Category = "GravityWhipThrown")
    FHazePlaySequenceData ThrownStart;

    UPROPERTY(BlueprintReadOnly, Category = "GravityWhipThrown")
    FHazePlaySequenceData ThrownMh;

    UPROPERTY(BlueprintReadOnly, Category = "GravityWhipThrown")
    FHazePlaySequenceData ThrownRecover;
}

class ULocomotionFeatureAIGravityWhipThrown : UHazeLocomotionFeatureBase
{
    default Tag = LocomotionFeatureAISkylineTags::GravityWhipThrown;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
    FLocomotionFeatureAIGravityWhipThrownData FeatureData;
}