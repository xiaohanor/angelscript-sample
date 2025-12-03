struct FLocomotionFeatureScorpionSiegeOperatorOperateAnimData 
{
	UPROPERTY(Category = "Operate")
    FHazePlaySequenceData Operate;
}

class ULocomotionFeatureScorpionSiegeOperatorOperate : UHazeLocomotionFeatureBase  
{
	default Tag = LocomotionFeatureAIScorpionSiegeOperatorTags::Operate;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureScorpionSiegeOperatorOperateAnimData AnimData;
}