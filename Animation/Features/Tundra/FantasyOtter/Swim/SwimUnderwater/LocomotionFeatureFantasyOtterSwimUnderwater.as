struct FLocomotionFeatureFantasyOtterSwimUnderwaterAnimData
{
	UPROPERTY(Category = "Swimming")
	FHazePlayBlendSpaceData UnderwaterMh;

	UPROPERTY(Category = "Swimming")
	FHazePlayBlendSpaceData UnderwaterSwimStart;

	UPROPERTY(Category = "Swimming")
	FHazePlayBlendSpaceData UnderwaterSwimBS;
	
	UPROPERTY(Category = "Swimming")
	FHazePlayBlendSpaceData UnderwaterStop;

	UPROPERTY(Category = "Dash")
	FHazePlayBlendSpaceData Dash_Var1;

	UPROPERTY(Category = "Interact")
	FHazePlaySequenceData TailLaunch;
	
	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData UnderwaterAdditiveBanking;

	UPROPERTY(Category = "Additive")
	FHazePlayBlendSpaceData UnderwaterAdditivePitching;
}

class ULocomotionFeatureFantasyOtterSwimUnderwater : UHazeLocomotionFeatureBase
{
	default Tag = n"UnderwaterSwimming";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureFantasyOtterSwimUnderwaterAnimData AnimData;

    UPROPERTY(BlueprintReadOnly, Category = "Physics")
    UHazePhysicalAnimationProfile PhysAnimProfile;



	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph

	UPROPERTY(Category = "Settings")
	float MaxTurnSpeed = 500;

	
	
}
