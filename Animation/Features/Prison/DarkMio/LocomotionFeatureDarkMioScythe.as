struct FLocomotionFeatureDarkMioScytheAnimData
{
	UPROPERTY(Category = "Fly")
	FHazePlaySequenceData FlyMH;


	UPROPERTY(Category = "GroundTrail")
	FHazePlaySequenceData GroundTrailEnter;

	UPROPERTY(Category = "GroundTrail")
	FHazePlaySequenceData GroundTrailAttack;

	UPROPERTY(Category = "GroundTrail")
	FHazePlaySequenceData GroundTrailEnd;


	UPROPERTY(Category = "Spiral")
	FHazePlaySequenceData Spiral;

	UPROPERTY(Category = "Spiral")
	FHazePlaySequenceData SpiralEnd;


	UPROPERTY(Category = "Wave")
	FHazePlaySequenceData WaveEnter;

	UPROPERTY(Category = "Wave")
	FHazePlaySequenceData WaveAttack;

	UPROPERTY(Category = "Wave")
	FHazePlaySequenceData WaveEnd;


	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData DashEnter;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData DashMH;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData DashStart;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData DashAttack;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData DashEnd;

	UPROPERTY(Category = "Dash")
	FHazePlaySequenceData DashEndAirborne;


	UPROPERTY(Category = "Clone")
	FHazePlaySequenceData CloneStart;

	UPROPERTY(Category = "Clone")
	FHazePlaySequenceData CloneMH;

	UPROPERTY(Category = "Clone")
	FHazePlaySequenceData CloneTelegraphEnter;

	UPROPERTY(Category = "Clone")
	FHazePlaySequenceData CloneTelegraphMH;

	UPROPERTY(Category = "Clone")
	FHazePlaySequenceData CloneAttack;


	UPROPERTY(Category = "HorizontalSlash")
	FHazePlaySequenceData HorizontalSlashEnter;

	UPROPERTY(Category = "HorizontalSlash")
	FHazePlaySequenceData HorizontalSlashAttack;

	UPROPERTY(Category = "HorizontalSlash")
	FHazePlaySequenceData HorizontalSlashEnd;


	UPROPERTY(Category = "Platform")
	FHazePlaySequenceData Platform;


	UPROPERTY(Category = "ZigZag")
	FHazePlaySequenceData ZigZagEnter;

	UPROPERTY(Category = "ZigZag")
	FHazePlaySequenceData ZigZagAttack;

	UPROPERTY(Category = "ZigZag")
	FHazePlaySequenceData ZigZagEnd;


	UPROPERTY(Category = "ForceFields")
	FHazePlaySequenceData ForceFields;


	UPROPERTY(Category = "ForceFieldsRotate")
	FHazePlaySequenceData ForceFieldsRotateEnter;

	UPROPERTY(Category = "ForceFieldsRotate")
	FHazePlaySequenceData ForceFieldsRotateMH;

	UPROPERTY(Category = "ForceFieldsRotate")
	FHazePlaySequenceData ForceFieldsRotateEnd;


	UPROPERTY(Category = "Scissor")
	FHazePlaySequenceData ScissorEnter;

	UPROPERTY(Category = "Scissor")
	FHazePlaySequenceData ScissorAttack;

	UPROPERTY(Category = "Scissor")
	FHazePlaySequenceData ScissorEnd;


	UPROPERTY(Category = "Donut")
	FHazePlaySequenceData Donut;


	UPROPERTY(Category = "Debris")
	FHazePlaySequenceData DebrisGrabEnter;

	UPROPERTY(Category = "Debris")
	FHazePlaySequenceData DebrisGrabMH;

	UPROPERTY(Category = "Debris")
	FHazePlaySequenceData DebrisThrow;

	UPROPERTY(Category = "Debris")
	FHazePlaySequenceData DebrisGrab;

	UPROPERTY(Category = "Debris")
	FHazePlaySequenceData DebrisThrownMH;

	UPROPERTY(Category = "Debris")
	FHazePlaySequenceData DebrisDeflect;

	UPROPERTY(Category = "Debris")
	FHazePlaySequenceData DebrisHitReaction;

	UPROPERTY(Category = "Debris")
	FHazePlaySequenceData DebrisHackable;


	UPROPERTY(Category = "HMP")
	FHazePlaySequenceData HMPEnter;

	UPROPERTY(Category = "HMP")
	FHazePlaySequenceData HMPMH;

	UPROPERTY(Category = "HMP")
	FHazePlaySequenceData HMPLaunch;

	UPROPERTY(Category = "HMP")
	FHazePlaySequenceData HMPHitReaction;


	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamEnter;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamMH;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamHitReactionFwd;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamHitReactionBack;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamHitReactionLeft;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamHitReactionRight;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamInterruptedFwd;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamInterruptedBack;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamInterruptedLeft;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamInterruptedRight;

	UPROPERTY(Category = "MagSlam")
	FHazePlaySequenceData MagSlamEnd;


}

class ULocomotionFeatureDarkMioScythe : UHazeLocomotionFeatureBase
{
	default Tag = n"DarkMioScythe";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureDarkMioScytheAnimData AnimData;
}
