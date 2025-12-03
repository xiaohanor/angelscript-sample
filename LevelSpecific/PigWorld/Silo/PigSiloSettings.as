class UPigSiloMovementSettings : UHazeComposableSettings
{
	UPROPERTY()
	float MoveSpeedMin = 300.0;

	UPROPERTY()
	float MoveSpeedMax = 800.0;

	UPROPERTY()
	float CurrentMoveSpeed = MoveSpeedMax;

	UPROPERTY()
	float TumbleDuration = 0.5;

	UPROPERTY()
	float TumbleDecelerationDuration = 0.3;

	UPROPERTY()
	float TumbleSpeedRecoveryTime = 0.4;



}