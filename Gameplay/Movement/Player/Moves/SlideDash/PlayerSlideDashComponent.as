

class UPlayerSlideDashComponent : UActorComponent
{
	UPROPERTY()
	UPlayerSlideDashSettings Settings;

	UPROPERTY()
	bool bForceDash = false;

	UPROPERTY()
	bool bDashing = false;

	UPROPERTY()
	UCurveFloat DashCurve;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UPlayerSlideDashSettings::GetSettings(Cast<AHazeActor>(Owner));
	}
}