struct FLocomotionFeatureSlowMoFireAnimData
{
	UPROPERTY(Category = "SlowMoFire")
	FHazePlaySequenceData SlowMoStartJump;

	UPROPERTY(Category = "SlowMoFire")
	FHazePlaySequenceData SlowMoMh;

	UPROPERTY(Category = "SlowMoFire")
	FHazePlaySequenceData Landing;

	UPROPERTY(Category = "SlowMoFire")
	FHazePlayBlendSpaceData SlowMoShootGrenade;

	UPROPERTY(Category = "SlowMoFire")
	FHazePlayBlendSpaceData SlowMoShootGrenadeDetonate;

	UPROPERTY(Category = "SlowMoFire")
	FHazePlayBlendSpaceData SlowMoShootCopsGun;

	UPROPERTY(Category = "SlowMoFire")
	FHazePlayBlendSpaceData SlowMoAimCopsGun;

	UPROPERTY(Category = "SlowMoFire")
	FHazePlaySequenceData SlowMoShootCopsGunAnim;
}

class ULocomotionFeatureSlowMoFire : UHazeLocomotionFeatureBase
{
	default Tag = n"SlowMoFire";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureSlowMoFireAnimData AnimData;
}
