struct FLocomotionFeatureGrappleAnimData
{
	UPROPERTY(BlueprintReadOnly, Category = "Grounded|Throw")
    FHazePlaySequenceData GroundThrow_1;

	UPROPERTY(Category = "Grounded|Throw")
    FHazePlaySequenceData GroundThrowUp_1;

	UPROPERTY(Category = "Grounded|Throw")
    FHazePlayBlendSpaceData GroundThrow_BS;

	UPROPERTY(Category = "Grounded|Throw")
    FHazePlayBlendSpaceData GroundThrowLeft_BS;

	UPROPERTY(Category = "Grounded|Throw")
    FHazePlayBlendSpaceData GroundThrowRight_BS;

	UPROPERTY(Category = "Grounded|Pull")
    FHazePlaySequenceData GroundPull_1;

	UPROPERTY(Category = "Grounded|Pull")
    FHazePlaySequenceData GroundPullUp_1;

	UPROPERTY(Category = "Grounded|Launch")
    FHazePlaySequenceData GroundLaunch_1;

	UPROPERTY(Category = "Grounded|Launch")
    FHazePlaySequenceData GroundLaunchUp_1;

	UPROPERTY(Category = "Grounded|Launch")
    FHazePlaySequenceData GroundLaunch_MH_1;

	UPROPERTY(Category = "InAir|Throw")
    FHazePlaySequenceData AirThrow_1;

	UPROPERTY(Category = "InAir|Throw")
    FHazePlaySequenceData AirThrowLeft_1;

	UPROPERTY(Category = "InAir|Throw")
    FHazePlaySequenceData AirThrowRight_1;

	UPROPERTY(Category = "InAir|ToPoint")
    FHazePlaySequenceData AirToPointPull_1;

	UPROPERTY(Category = "InAir|ToPoint")
    FHazePlaySequenceData AirToPointPullLeft_1;

	UPROPERTY(Category = "InAir|ToPoint")
    FHazePlaySequenceData AirToPointPullRight_1;

	UPROPERTY(Category = "InAir|ToPoint")
    FHazePlayBlendSpaceData AirToPointPullBS_1;

	UPROPERTY(Category = "InAir|ToPoint")
    FHazePlayBlendSpaceData AirToPointPullLeftBS_1;

	UPROPERTY(Category = "InAir|ToPoint")
    FHazePlayBlendSpaceData AirToPointPullRightBS_1;

	UPROPERTY(Category = "InAir|Pull")
    FHazePlaySequenceData AirPull_1;

	UPROPERTY(Category = "InAir|Pull")
    FHazePlaySequenceData AirPullLeft_1;

	UPROPERTY(Category = "InAir|Pull")
    FHazePlaySequenceData AirPullRight_1;

	UPROPERTY(Category = "InAir|Pull")
    FHazePlaySequenceData AirPullUp_1;

	UPROPERTY(Category = "InAir|Pull")
    FHazePlaySequenceData AirPullUpLeft_1;

	UPROPERTY(Category = "InAir|Pull")
    FHazePlaySequenceData AirPullUpRight_1;

	UPROPERTY(Category = "InAir|Launch")
    FHazePlaySequenceData AirLaunch_1;

	UPROPERTY(Category = "InAir|Launch")
    FHazePlaySequenceData AirLaunchLeft_1;

	UPROPERTY(Category = "InAir|Launch")
    FHazePlaySequenceData AirLaunchRight_1;

	UPROPERTY(Category = "InAir|Launch")
    FHazePlaySequenceData AirLaunchUp_1;

	UPROPERTY(Category = "InAir|Launch")
    FHazePlaySequenceData AirLaunchUpLeft_1;

	UPROPERTY(Category = "InAir|Launch")
    FHazePlaySequenceData AirLaunchUpRight_1;

	UPROPERTY(Category = "InAir|Launch")
    FHazePlaySequenceData AirLaunchDown_1;

	UPROPERTY(Category = "InAir|Launch")
    FHazePlaySequenceData AirLaunch_MH_1;

	UPROPERTY(Category = "ToPoint|Exit")
    FHazePlaySequenceData ToPointExit_1;
	
	UPROPERTY(Category = "ToPoint|Exit")
    FHazePlaySequenceData ToPointExit_Run;

	UPROPERTY(Category = "ToPoint|Exit")
    FHazePlaySequenceData ToPointExitLeft_1;
	
	UPROPERTY(Category = "ToPoint|Exit")
    FHazePlaySequenceData ToPointExitLeft_Run;

	UPROPERTY(Category = "ToPoint|Exit")
    FHazePlaySequenceData ToPointExitRight_1;
	
	UPROPERTY(Category = "ToPoint|Exit")
    FHazePlaySequenceData ToPointExitRight_Run;

	UPROPERTY(Category = "ToPoint|Exit")
	FHazePlayBlendSpaceData ToPointExitBS_1;
	
	UPROPERTY(Category = "ToPoint|Exit")
	FHazePlayBlendSpaceData ToPointExitMoveBS_1;

	UPROPERTY(Category = "ToPoint|Exit")
	FHazePlayBlendSpaceData ToPointExitLeftBS_1;

	UPROPERTY(Category = "ToPoint|Exit")
	FHazePlayBlendSpaceData ToPointExitMoveLeftBS_1;

	UPROPERTY(Category = "ToPoint|Exit")
	FHazePlayBlendSpaceData ToPointExitRightBS_1;

	UPROPERTY(Category = "ToPoint|Exit")
	FHazePlayBlendSpaceData ToPointExitMoveRightBS_1;

	UPROPERTY(Category = "ToPointGrounded|Exit")
	FHazePlayBlendSpaceData ToPointGroundedExitBS_1;

	UPROPERTY(Category = "ToPointGrounded|Exit")
	FHazePlayBlendSpaceData ToPointGroundedExitMoveBS_1;

	UPROPERTY(Category = "Slide|Pull")
    FHazePlaySequenceData SlideGroundPull_1;
	
	UPROPERTY(Category = "Slide|Pull")
    FHazePlaySequenceData SlideGroundPullClose_1;

	UPROPERTY(Category = "Slide|Pull")
    FHazePlaySequenceData SlideAirPull_1;

	UPROPERTY(Category = "Slide|Pull")
    FHazePlaySequenceData SlideAirPullLeft_1;

	UPROPERTY(Category = "Slide|Pull")
    FHazePlaySequenceData SlideAirPullRight_1;

	UPROPERTY(Category = "Slide|Landing")
    FHazePlaySequenceData SlideGrapple_Anticipation;


	UPROPERTY(Category = "Slide|Landing")
    FHazePlaySequenceData SlideGrapple_MH_1;

	UPROPERTY(Category = "Slide|Landing")
    FHazePlaySequenceData SlideGrapple_Landing_1;

	UPROPERTY(Category = "Wallrun|To Left")
    FHazePlaySequenceData WallrunToLeftGroundPull_1;

	UPROPERTY(Category = "Wallrun|To Left")
    FHazePlaySequenceData WallrunToLeftAirPull_1;

	UPROPERTY(Category = "Wallrun|To Left")
    FHazePlaySequenceData WallrunToLeftAirPullLeft_1;

	UPROPERTY(Category = "Wallrun|To Left")
    FHazePlaySequenceData WallrunToLeftAirPullRight_1;

	UPROPERTY(Category = "Wallrun|To Right")
    FHazePlaySequenceData WallrunToRightGroundPull_1;

	UPROPERTY(Category = "Wallrun|To Right")
    FHazePlaySequenceData WallrunToRightAirPull_1;

	UPROPERTY(Category = "Wallrun|To Right")
    FHazePlaySequenceData WallrunToRightAirPullLeft_1;

	UPROPERTY(Category = "Wallrun|To Right")
    FHazePlaySequenceData WallrunToRightAirPullRight_1;

	UPROPERTY(Category = "Interrupt|Throw")
    FHazePlaySequenceData InterruptThrow_1;

	UPROPERTY(Category = "Interrupt|Pull")
    FHazePlaySequenceData InterruptPull_1;

	UPROPERTY(Category = "Anticipation")
    FHazePlaySequenceData Anticipation_1;

	UPROPERTY(Category = "Anticipation")
    FHazePlaySequenceData AnticipationMH_1;

	UPROPERTY(Category = "Anticipation")
    FHazePlaySequenceData AnticipationMH_Pole;

}

class ULocomotionFeatureGrapple : UHazeLocomotionFeatureBase
{
	default Tag = n"Grapple";

	// Struct that will hold all animation assets that is going to be used in the Anim Graph
	UPROPERTY(BlueprintReadOnly, meta = (ShowOnlyInnerProperties))
	FLocomotionFeatureGrappleAnimData AnimData;

	// Add Custom Variables Here, basically anything that isn't going to be used in the Anim Graph
}

enum EHazeGrappleHookHeightMomentumAnimationType
{
	Upwards,
	Same,
	Downwards,

}
