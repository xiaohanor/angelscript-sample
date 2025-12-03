
class UPlayerFloorSlowdownComponent : UActorComponent
{
	UPROPERTY()
	UPlayerFloorSlowdownSettings Settings;

	UPROPERTY()
	bool bInSlowDownState;

	FVector EndLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerFloorSlowdownSettings::GetSettings(Cast<AHazeActor>(Owner));
	}
}