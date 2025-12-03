
class UPlayerPoleClimbSettings : UHazeComposableSettings
{
	 /***	PoleClimb Settings	***/
	
	//Vertical Input Deadzone
	UPROPERTY(Category = PoleClimbSettings)
	float VerticalDeadZone = 0.3;

	//Horizontal Input Deadzone
	UPROPERTY(Category = PoleClimbSettings)
	float HorizontalDeadZone = 0.3;

	//MaxHeight is calculated by capsule height of player + this offset
	UPROPERTY(Category = PoleClimbSettings)
	float MaxHeightOffset = 0;

	//How long after leaving a poleactor can we enter another one
	UPROPERTY(Category = PoleClimbSettings)
	float PoleCooldown = 0.25;

	UPROPERTY(Category = PoleClimbSettings, Meta = (EditCondition = "bUseOverridePoleType"))
	EPoleTypeOverride OverridePoleType = EPoleTypeOverride::None;

	UPROPERTY(Category = PoleClimbVelocitySettings)
	float ClimbSpeed = 300.0;

	UPROPERTY(Category = PoleClimbVelocitySettings)
	float MinimumVerticalSpeed = 75.0;

	UPROPERTY(Category = PoleClimbVelocitySettings)
	float TerminalSlideSpeed = 2500;

	// This can also added by the poles
	// This is how much we slide by default
	// Only used if >= 0
	UPROPERTY(Category = PoleClimbVelocitySettings)
	float SlideDefaultAmount = -1;

	// If input is given, this is applied
	UPROPERTY(Category = PoleClimbVelocitySettings)
	float SlideGravityScalar = 0.25;

	UPROPERTY(Category = PoleClimbVelocitySettings)
	float SlideBrakeInterpSpeed = 1800;

	UPROPERTY(Category = PoleClimbVelocitySettings)
	float ClimbInterpSpeed = 600;

	UPROPERTY(Category = PoleClimbTurnSettings)
	float MinimumRotationSpeed = 90.0;

	UPROPERTY(Category = PoleClimbTurnSettings)
	float MaxRotationSpeed = 180.0;
	
	UPROPERTY(Category = PoleClimbTurnSettings)
	float TurnAroundDuration = 0.5;

	UPROPERTY(Category = PoleClimbTurnSettings)
	float TurnAroundCooldown = 0.15;

	const float SlideNoInputDrag = 0.04;

	const float MinimumDragValue = 0.5;

	//Height offset at bottom of pole to prevent pushing capsule into floor
	const float PoleMinHeightOffset = 2.0;

	//How far from pole is capsule positioned
	const float PlayerPoleHorizontalOffset = 45.0;

	/***	EnterSettings ***/

	//How far off the Max/Min Heights can we be for a valid enter height
	const float PoleEnterHeightMargin = 50.0;

	// Duration for transition into poleclimbing from normal movement
	const float EnterMoveDuration = 0.15;

	const float TurnaroundEnterDuration = 0.3;

	// Duration for transitioning down from perch into poleclimb
	const float ClimbDownFromPerchDuration = 0.5;

	const float EnterInputAcceptanceAngle = 30;

	/***	Exit Settings	***/

	//
	UPROPERTY(Category = PoleClimbExitSettings)
	float CancelOutwardsImpulse = 300.0;

	const float JumpOutAnticipationTime = 0.1;	

	//
	UPROPERTY(Category = PoleClimbExitSettings)
	float JumpOutHorizontalImpulse = 800;

	UPROPERTY(Category = PoleClimbExitSettings)
	float JumpOutVerticalImpulse = 700; 

	//Climb Up To Perch Duration
	const float ClimbUpToPerchDuration = 0.3;

	/***	Jump Up / PoleDash	***/

	//DashBufferWindow
	UPROPERTY(Category = PoleClimbDashSettings)
	float DashInputBufferWindow = 0.2;

	//
	UPROPERTY(Category = PoleClimbDashSettings)
	float DashCooldown = 0.15;

	//
	UPROPERTY(Category = PoleClimbDashSettings)
	float DashAccelerationDuration = 0.09;

	//DashDuration once at peak velocity
	UPROPERTY(Category = PoleClimbDashSettings)
	float DashDuration = 0.33;
	
	//
	UPROPERTY(Category = PoleClimbDashSettings)
	float DashDecelerationDuration = 0.24;

	//Pole Jump Up / Dash Minimum Duration
	UPROPERTY(Category = PoleClimbDashSettings)
	float DashMinDuration = 0.15;

	//How far dash will take you up the pole
	UPROPERTY(Category = PoleClimbDashSettings)
	float DashDistanceMax = 300;

	//Required distance left on the pole for a dash
	UPROPERTY(Category = PoleClimbDashSettings)
	float DashDistanceMin = 200;
}