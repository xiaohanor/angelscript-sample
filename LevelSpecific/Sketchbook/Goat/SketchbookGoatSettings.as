namespace Sketchbook::Goat
{
	/**
	 * Mounted
	 */

	const float GravityScale = 2.5;
	const float TerminalVelocity = 600;
	const float GroundMoveSpeed = 800;
	const float GroundAcceleration = 1200;
	const float AirMoveSpeed = 700;
	const float AirAcceleration = 400;
	const float GravityAcceleration = 2000;
	const float MinJumpDelay = 0.5;
	const float YawAngle = 20;
	const float RunWiggleAngle = 2;
	const float RunBobHeight = 40;
	const FHazeRange RunBobSpeed = FHazeRange(0.03, 0.01);

	/**
	 * Jump
	 */
	
	const float JumpHeight = 250;
	const float JumpSpeed = 800;

	const float PerchJumpSpeed = 30;
	const float PerchJumpHeight = 200;


	namespace Tags
	{
		const FName SketchbookGoat = n"SketchbookGoat";
	}
};