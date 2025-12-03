struct FLocomotionFeatureWingSuitEnterAnimData
{
	UPROPERTY(Category = "Enter")
	FHazePlayBlendSpaceData Enter;

	UPROPERTY(Category = "Enter")
	FHazePlayBlendSpaceData FlyingOffRamp;

	UPROPERTY(Category = "Enter")
	FHazePlayBlendSpaceData AdditiveFlyingOffRamp;

	UPROPERTY(Category = "Enter")
	FHazePlaySequenceData Land;

}

struct FLocomotionFeatureWingSuitAnimData
{
	UPROPERTY(Category = "Mh")
	FHazePlayBlendSpaceData Mh;

	UPROPERTY(Category = "Mh")
	FHazePlayBlendSpaceData AdditiveMh;
}

struct FLocomotionFeatureWingSuitBarrelRollAnimData
{
	UPROPERTY(Category = "BarrelRoll")
	FHazePlayBlendSpaceData BarrelRoll;

	UPROPERTY(Category = "BarrelRoll")
	FHazePlayBlendSpaceData BarrelRollLeft;

	UPROPERTY(Category = "BarrelRoll")
	FHazePlayBlendSpaceData BarrelRollRight;
}

struct FLocomotionFeatureWingSuitCrashDiveAnimData
{
	UPROPERTY(Category = "CrashDive")
	FHazePlaySequenceData Enter;
    
	UPROPERTY(Category = "CrashDive")
	FHazePlaySequenceData Mh;
    
	UPROPERTY(Category = "CrashDive")
	FHazePlaySequenceData Exit;
}


struct FLocomotionFeatureWingSuitGrappleAnimData
{
	UPROPERTY(Category = "Grapple")
	FHazePlaySequenceData Throw;
    
	UPROPERTY(Category = "Grapple")
	FHazePlaySequenceData Pull;

	UPROPERTY(Category = "Grapple")
	FHazePlaySequenceData ToTrain;

	UPROPERTY(Category = "Grapple")
	FHazePlaySequenceData ToTrainFast;
    
}





class ULocomotionFeatureWingSuit : UHazeLocomotionFeatureBase
{
	default Tag = n"WingSuit";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWingSuitEnterAnimData EnterAnimData;
	
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWingSuitAnimData AnimData;

	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWingSuitBarrelRollAnimData BarrelRollAnimData;

	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWingSuitCrashDiveAnimData CrashDiveAnimData;

	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureWingSuitGrappleAnimData GrappleAnimData;

	

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}
