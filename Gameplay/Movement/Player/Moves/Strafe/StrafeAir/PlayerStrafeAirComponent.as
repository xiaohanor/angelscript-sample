
class UPlayerStrafeAirComponent : UActorComponent
{
	UPROPERTY()
	UPlayerStrafeAirSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerStrafeAirSettings::GetSettings(Cast<AHazeActor>(Owner));
	}
}