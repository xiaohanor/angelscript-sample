class UPlayerLandingSettings : UHazeComposableSettings
{
	UPROPERTY(BlueprintReadOnly)
	FPlayerLanding Fatal;
	default Fatal.Speed = 2500.0;
	default Fatal.Distance = 1500.0;

	UPROPERTY(BlueprintReadOnly)
	FPlayerLanding Stunned;
	default Stunned.Speed = 2000.0;
	default Stunned.Distance = 1350.0;

	UPROPERTY()
	float StunnedDuration = 1.25;
}

struct FPlayerLanding
{
	UPROPERTY()
	float Speed;
	
	UPROPERTY()
	float Distance;
}