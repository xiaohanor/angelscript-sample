struct FLocomotionFeatureJetpackAnimData
{
	UPROPERTY(Category = "Jetpack")
	FHazePlaySequenceData Start;

	UPROPERTY(Category = "Jetpack")
	FHazePlaySequenceData Landing;

	UPROPERTY(Category = "Jetpack")
	FHazePlayBlendSpaceData Flying;

	UPROPERTY(Category = "Jetpack")
	FHazePlaySequenceData FlyingUp;

	UPROPERTY(Category = "Jetpack")
	FHazePlayBlendSpaceData Dash;

	UPROPERTY(Category = "Jetpack")
	FHazePlaySequenceData Refill;

	UPROPERTY(Category = "Jetpack")
	FHazePlayBlendSpaceData RefillBS;

	UPROPERTY(Category = "Jetpack")
	FHazePlaySequenceData TunnelDash;



	
}

class ULocomotionFeatureJetpack : UHazeLocomotionFeatureBase
{
	default Tag = n"Jetpack";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureJetpackAnimData AnimData;
}
