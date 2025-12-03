struct FLocomotionFeatureScorpionSiegeOperatorRepairAnimData 
{
	UPROPERTY(Category = "Repair")
    FHazePlaySequenceData Repair;
}

class ULocomotionFeatureScorpionSiegeOperatorRepair : UHazeLocomotionFeatureBase  
{
	default Tag = LocomotionFeatureAIScorpionSiegeOperatorTags::Repair;

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureScorpionSiegeOperatorRepairAnimData AnimData;
}