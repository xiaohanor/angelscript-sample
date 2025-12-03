class UBattlefieldHoverboardLevelRubberbandingSettings : UHazeComposableSettings
{
	/** The maximum amount of rubberbanding speed, either negatively or positively */
	UPROPERTY(Category = "Max Speed")
	float MaxRubberbandingSpeed = 700.0;
	
	/** How much of the Max rubberbanding speed can be applied positively */
	UPROPERTY(Category = "Max Speed")
	float SpeedGainMultiplier = 0.7;
	
	/** How much of the max rubberbanding speed can be applied negatively */
	UPROPERTY(Category = "Max Speed")
	float SpeedLossMultiplier = 0.5;
	
	UPROPERTY(Category = "Max Speed")
	float DeltaSplineDistanceAtWhichMaxSpeed = 4000.0;

	UPROPERTY(Category = "Preferred Ahead")
	EHazePlayer PreferredAheadPlayer = EHazePlayer::Zoe;

	UPROPERTY(Category = "Preferred Ahead")
	float PreferredAheadDistance = 800.0;
};