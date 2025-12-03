class UTeenDragonTailGeckoClimbSettings : UHazeComposableSettings
{
	// WALL ATTACHMENT

	// How far the dragon checks downwards if it is on a climbable surface
	// Doesn't block if hit, which means that it can be climbing on a wall underneath the one it's actually on
	// Increase to help with stickiness when climbing around shallow colliders
	UPROPERTY()
	float WallCheckDistance = 100;

	UPROPERTY()
	float WallClimbActivationCooldown = 0.5;

	// MOVEMENT ON THE WALL

	// The angle which is allowed to go between walls
	// Lower it if you want to fall off hard increases between walls, and get stuck at hard decreases 
	UPROPERTY()
	float ClimbableAngle = 60;

	UPROPERTY()
	float MinimumInput = 0.4;

	UPROPERTY()
	float MinimumSpeed = 320.0;

	UPROPERTY()
	float MaximumSpeed = 650.0;

	UPROPERTY()
	float AccelerationSpeed = 2200.0;

	UPROPERTY()
	float SlowDownInterpSpeed = 8000.0;

	UPROPERTY()
	float ClimbTurnSpeed = 4;

	// JUMP

	UPROPERTY()
	float JumpHorizontalSpeed = 2400;

	UPROPERTY()
	float JumpLength = 1000;

	UPROPERTY()
	float JumpTurnSpeed = 2;

	// DASH

	UPROPERTY()
	float DashMaxSpeed = 3000;

	UPROPERTY()
	float DashDepthCheck = 200;

	UPROPERTY()
	float DashDuration = 0.5;

	UPROPERTY()
	float DashCooldown = 0.3;

	UPROPERTY()
	FRuntimeFloatCurve DashSpeedCurve;
	default DashSpeedCurve.AddDefaultKey(0, 1);
	default DashSpeedCurve.AddDefaultKey(1, 0.5);

	// JUMP OFF FROM THE WALL
	
	// How long the jump off lasts
	UPROPERTY()
	float ExitDuration = 0.2;

	// How fast the jump off is
	UPROPERTY()
	float ExitSpeed = 500;

	// How fast the world up changes after missing a jump while climbing
	UPROPERTY()
	float JumpMissTransitionDuration = 0.7;

	// How much the speed not pointing towards world down slows down
	// (Use to make dragon not look weird when missing jumps)
	UPROPERTY()
	float JumpMissHorizontalSlowDownSpeed = 20;

	// CAMERA

	UPROPERTY()
	float CameraSettingsBlendInTime = 1.5;

	UPROPERTY()
	float CameraSettingsBlendOutTime = 1.5;

	// How much the camera should roll 0 - 1
	// 1 being 90 degrees off the wall when looking along wall
	UPROPERTY()
	float CameraRollMultiplier = 0.5;

	UPROPERTY()
	float CameraRollInterpSpeed = 5.5;

	// How camera Transitions when leaping onto walls
	UPROPERTY()
	float CameraTransitionJumpOnWallSpeed = 2.0;

	// How camera Transitions when exiting walls
	// (B press)
	UPROPERTY()
	float CameraTransitionExitWallSpeed = 7.0;

	// How camera Transitions when exiting walls
	// (Jump)
	UPROPERTY()
	float CameraTransitionJumpMissSpeed = 2.0;
	

	UPROPERTY()
	float LandOnWallStartCameraTransitionDuration = 1.2;

	UPROPERTY()
	float LandOnWallCameraTransitionPitchDownDegrees = 30.0;
}