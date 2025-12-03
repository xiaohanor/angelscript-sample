
class UPlayerJumpSettings : UHazeComposableSettings
{
	UPROPERTY()
	float InputBufferWindow = 0.2;

	// Upwards impulse applied while jumping
	UPROPERTY()
	float Impulse = 750.0;

	// Upwards impulse applied while jumping
	UPROPERTY()
	float PerchImpulse = 750.0;

	UPROPERTY()
	float HorizontalPerchImpulseMultiplier = 0.9333;

	//Trying out calculating these inside the move instead to allow for different amounts of air controll/air speed depending on how fast your horizontal velocity is when starting the jump
	
	// // Target horizontal speed
	// UPROPERTY()
	// float HorizontalMoveSpeed = 640.0;

	// // Interp speed of your velocity (units per second)
	// UPROPERTY()
	// float HorizontalVelocityInterpSpeed = 1800.0;
	

	// Rotation speed of the player towards your input
	UPROPERTY()
	float FacingDirectionInterpSpeed = 2.5;

	// Cannot trigger air jump within this duration of a normal jump (provided it's still active)
	UPROPERTY()
	float PostJumpAirJumpCooldown = 0.175;

	// Cannot trigger air jump within this duration of a normal jump (provided it's still active)
	UPROPERTY()
	float PostJumpAirDashCooldown = 0.08;
}