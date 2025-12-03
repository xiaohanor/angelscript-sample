namespace BabyDragonAirBoost
{
	// How fast to boost up
	const float JumpImpulse = 200.0;
	// Minimum duration for gliding after pressing the button
	const float GlideMinimumDuration = 0.5;
	// How fast to change facing rotation while boosting
	const float FacingDirectionInterpSpeed = 4.0;

	// Multiplier to gravity while gliding down
	const float GlideGravityMultiplier = 0.08;
	// Terminal velocity for the player while gliding
	const float GlideTerminalVelocity = 400.0;

	// How much upwards speed is lost if vertical velocity is positive
	const FHazeRange GlideUpwardsDeceleration = FHazeRange(1200, 3000);
	// Deceleration based on how fast the player is going, vertical speed above "Max" will have maximum deceleration, vertical speed below "Min" will have minimum deceleration
	const FHazeRange DecelerationSpeedRange = FHazeRange(200, 2000);
};