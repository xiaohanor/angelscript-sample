class UWindDirectionSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Wind")
	float WindNormalStrength = 20.0;

	UPROPERTY(Category = "Wind")
	float WindStrongStrength = 60.0;

	UPROPERTY(Category = "Wind")
	float WindDirectionAccelerationDuration = 10.0;
}