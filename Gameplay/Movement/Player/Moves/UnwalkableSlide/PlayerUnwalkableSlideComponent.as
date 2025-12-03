
class UPlayerUnwalkableSlideComponent : UActorComponent
{
	UPROPERTY()
	UPlayerUnwalkableSlideSettings Settings;

	UPROPERTY(BlueprintReadOnly)
	FPlayerUnwalkableSlideAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerUnwalkableSlideSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	float GetMovementTargetSpeed(float SpeedAlpha) const
	{
		return Math::Lerp(Settings.MinimumSpeed, Settings.MaximumSpeed, SpeedAlpha);
	}
}

struct FPlayerUnwalkableSlideAnimData
{
	UPROPERTY()
	bool bFalling = false;
}