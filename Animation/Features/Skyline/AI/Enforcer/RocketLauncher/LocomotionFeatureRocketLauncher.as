
struct FLocomotionFeatureRocketLauncherAnimData 
{

	UPROPERTY(Category = "RocketLauncher")
    FHazePlaySequenceData Aim;

	UPROPERTY(Category = "RocketLauncher")
    FHazePlaySequenceData Shoot;

	UPROPERTY(Category = "RocketLauncher")
    FHazePlaySequenceData MHToAim;


}

class ULocomotionFeatureRocketLauncher : UHazeLocomotionFeatureBase  
{

    UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureRocketLauncherAnimData AnimData;

}