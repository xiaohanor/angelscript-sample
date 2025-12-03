struct FLocomotionFeatureSkylineTorWhipSlipAnimData
{	
	UPROPERTY(Category = "WhipSlip")
	FHazePlaySequenceData WhipSlipStart;

	UPROPERTY(Category = "WhipSlip")
	FHazePlaySequenceData WhipSlipEnd;
}

class ULocomotionFeatureSkylineTorWhipSlip : UHazeLocomotionFeatureBase
{
	default Tag = SkylineTorFeatureTags::WhipSlip;

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSkylineTorWhipSlipAnimData AnimData;

}