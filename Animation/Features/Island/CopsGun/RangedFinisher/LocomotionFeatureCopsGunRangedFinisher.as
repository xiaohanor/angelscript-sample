struct FLocomotionFeatureCopsGunRangedFinisherAnimData
{
	UPROPERTY(Category = "CopsGunRangedFinisher")
	FHazePlaySequenceData ClockWiseFinisher_Kill_var1;

	UPROPERTY(Category = "CopsGunRangedFinisher")
	FHazePlaySequenceData ClockWiseFinisher_Settle_var1;
}

class ULocomotionFeatureCopsGunRangedFinisher : UHazeLocomotionFeatureBase
{
	default Tag = n"CopsGunRangedFinisher";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureCopsGunRangedFinisherAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
