struct FLocomotionFeatureSwimUnderwaterAnimData
{
	UPROPERTY(Category = "Surface")
	FHazePlaySequenceData SurfaceMH;

	UPROPERTY(Category = "Surface")
	FHazePlaySequenceData SurfaceFreestyleStart;

	UPROPERTY(Category = "Surface")
	FHazePlayBlendSpaceData SurfaceFreestyleSwim;
	
	UPROPERTY(Category = "Surface")
	FHazePlaySequenceData SurfaceStop;

	UPROPERTY(Category = "Surface")
	FHazePlaySequenceData SurfaceLedgeUp;


	UPROPERTY(Category = "Underwater")
	FHazePlaySequenceData DiveFromSurface;

	UPROPERTY(Category = "Underwater")
	FHazePlayBlendSpaceData UnderwaterMH;

	UPROPERTY(Category = "Underwater")
	FHazePlayBlendSpaceData UnderwaterStart;

	UPROPERTY(Category = "Underwater")
	FHazePlayBlendSpaceData UnderwaterSwim;

	UPROPERTY(Category = "Underwater")
	FHazePlaySequenceData UnderwaterStop;

	UPROPERTY(Category = "Underwater")
	FHazePlaySequenceData BreachSurface;

	UPROPERTY(Category = "Underwater")
	FHazePlayBlendSpaceData UnderwaterSwimStroke;

	UPROPERTY(Category = "Underwater")
	FHazePlaySequenceData UnderWaterSwimPaddleStartLeft;

	UPROPERTY(Category = "Underwater")
	FHazePlaySequenceData UnderWaterSwimPaddleStartRight;

	UPROPERTY(Category = "Underwater")
	FHazePlayBlendSpaceData UnderwaterSwimPaddle;

	UPROPERTY(Category = "Underwater")
	FHazePlaySequenceData UnderWaterSwimPaddleStopLeftHandFwd;

	UPROPERTY(Category = "Underwater")
	FHazePlaySequenceData UnderWaterSwimPaddleStopRightHandFwd;

	UPROPERTY(Category = "Underwater")
	FHazePlayBlendSpaceData UnderWaterSwimPaddleStop;

	UPROPERTY(Category = "Underwater|Slow")
	FHazePlayBlendSpaceData UnderwaterSwimSlow;

	UPROPERTY(Category = "Underwater|Additive")
	FHazePlayBlendSpaceData AdditiveBankingBS;

	UPROPERTY(Category = "Underwater|Additive")
	FHazePlayBlendSpaceData AdditivePitchBS;

	UPROPERTY(Category = "Underwater|Additive")
	FHazePlayBlendSpaceData AdditiveBankingStrokeBS;

	UPROPERTY(Category = "Underwater|Additive")
	FHazePlayBlendSpaceData AdditivePitchStrokeBS;



}

class ULocomotionFeatureSwimUnderwater : UHazeLocomotionFeatureBase
{
	default Tag = n"UnderwaterSwimming";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSwimUnderwaterAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
