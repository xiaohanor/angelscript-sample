struct FLocomotionFeatureJetskiAnimData
{
	UPROPERTY(Category = "Jetski")
	FHazePlayBlendSpaceData Surface;

	UPROPERTY(Category = "Jetski")
	FHazePlayBlendSpaceData AirMovement;

	UPROPERTY(Category = "Jetski")
	FHazePlaySequenceData Landing;

	UPROPERTY(Category = "UnderWater")
	FHazePlaySequenceData UnderWaterEnter;

	UPROPERTY(Category = "UnderWater")
	FHazePlayBlendSpaceData UnderWater;

	UPROPERTY(Category = "UnderWater")
	FHazePlaySequenceData UnderWaterJump;
	
	UPROPERTY(Category = "HitReaction")
	FHazePlaySequenceData HitReactionLeft;

	UPROPERTY(Category = "HitReaction")
	FHazePlaySequenceData HitReactionRight;
	
	UPROPERTY(Category = "HitReaction")
	FHazePlaySequenceData SolidGroundMh;
}

class ULocomotionFeatureJetski : UHazeLocomotionFeatureBase
{
	default Tag = n"Jetski";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureJetskiAnimData AnimData;
}
