class UIslandOverseerEyeSettings : UHazeComposableSettings
{	
	UPROPERTY()
	float EnterDuration = 3;

	UPROPERTY()
	float ReturnDuration = 3;

	UPROPERTY()
	float FlyByMoveToSpeed = 1300;

	UPROPERTY()
	float FlyByAttackSpeed = 1300;

	UPROPERTY()
	float FlyByAttackAccelerationDuration = 3;

	UPROPERTY()
	float FlyByTelegraphDuration = 2;
}