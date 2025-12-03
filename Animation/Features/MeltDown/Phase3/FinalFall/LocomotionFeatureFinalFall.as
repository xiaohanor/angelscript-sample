struct FLocomotionFeatureFinalFallAnimData
{
	UPROPERTY(Category = "FinalFall")
	FHazePlayBlendSpaceData Fall_MH;

	UPROPERTY(Category = "FinalFall")
	FHazePlayBlendSpaceData Additive_BS;

	UPROPERTY(Category = "FinalFall")
	FHazePlaySequenceData Hit_Crane;

	UPROPERTY(Category = "FinalFall")
	FHazePlaySequenceData Hit_Debris;

	UPROPERTY(Category = "FinalFall")
	FHazePlaySequenceData Hit_Laser;

	UPROPERTY(Category = "FinalFall")
	FHazePlaySequenceData Hit_Ships;

	UPROPERTY(Category = "FinalFall")
	FHazePlaySequenceData Hit_Worm;

	UPROPERTY(Category = "FinalFall")
	FHazePlaySequenceData Hit_Ice;

	UPROPERTY(Category = "HitReactions|Left")
	FHazePlayRndSequenceData Hit_LeftSmall;

	UPROPERTY(Category = "HitReactions|Left")
	FHazePlayRndSequenceData Hit_LeftBig;

	UPROPERTY(Category = "HitReactions|Left")
	FHazePlayRndSequenceData Hit_LeftSpin;

	UPROPERTY(Category = "HitReactions|Right")
	FHazePlayRndSequenceData Hit_RightSmall;

	UPROPERTY(Category = "HitReactions|Right")
	FHazePlayRndSequenceData Hit_RightBig;

	UPROPERTY(Category = "HitReactions|Right")
	FHazePlayRndSequenceData Hit_RightSpin;
	
	UPROPERTY(Category = "HitReactions|Behind")
	FHazePlayRndSequenceData Hit_FwdBig;

	UPROPERTY(Category = "HitReactions|Behind")
	FHazePlayRndSequenceData Hit_FwdSpin;

	UPROPERTY(Category = "HitReactions|Behind")
	FHazePlayRndSequenceData Hit_BwdSpin;
	

}

class ULocomotionFeatureFinalFall : UHazeLocomotionFeatureBase
{
	default Tag = n"FinalFall";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFinalFallAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
