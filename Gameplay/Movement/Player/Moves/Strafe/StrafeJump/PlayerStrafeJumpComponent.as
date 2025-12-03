
class UPlayerStrafeJumpComponent : UActorComponent
{
	UPROPERTY()
	UPlayerStrafeJumpSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerStrafeJumpSettings::GetSettings(Cast<AHazeActor>(Owner));
	}
}