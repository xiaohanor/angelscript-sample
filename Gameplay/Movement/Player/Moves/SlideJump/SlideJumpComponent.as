

class UPlayerSlideJumpComponent : UActorComponent
{
	UPROPERTY()
	UPlayerSlideJumpSettings Settings;

	UPROPERTY()
	bool bJump = false;

	UPROPERTY()
	bool bStartedJump;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerSlideJumpSettings::GetSettings(Cast<AHazeActor>(Owner));
	}	
}