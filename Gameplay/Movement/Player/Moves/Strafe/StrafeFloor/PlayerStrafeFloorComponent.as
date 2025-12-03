
class UPlayerStrafeFloorComponent : UActorComponent
{
	UPROPERTY()
	UPlayerStrafeFloorSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerStrafeFloorSettings::GetSettings(Cast<AHazeActor>(Owner));
	}
}