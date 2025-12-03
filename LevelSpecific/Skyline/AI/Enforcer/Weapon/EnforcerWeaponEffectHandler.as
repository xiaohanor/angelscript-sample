UCLASS(Abstract)
class UEnforcerWeaponEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTelegraph(FEnforcerWeaponEffectTelegraphData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraph() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnAnticipation(FEnforcerWeaponEffectTelegraphData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopAnticipation() {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FEnforcerWeaponEffectLaunchParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReload(FEnforcerWeaponEffectReloadParams Params) {}
}

struct FEnforcerWeaponEffectTelegraphData
{
	UPROPERTY()
	FVector LaunchLocation;

	UPROPERTY()
	float Duration;

	FEnforcerWeaponEffectTelegraphData(FVector InLaunchLocation, float InDuration)
	{
		LaunchLocation = InLaunchLocation;
		Duration = InDuration;
	}
}

USTRUCT()
struct FEnforcerWeaponEffectLaunchParams
{
	UPROPERTY()
	FVector LaunchLocation;

	UPROPERTY()
	int NumShotsFired = 0;

	UPROPERTY()
	int MagazineSize = 0;

	FEnforcerWeaponEffectLaunchParams(int _NumShotsFired, int _MagazineSize, FVector _LaunchLocation)
	{
		NumShotsFired = _NumShotsFired;
		MagazineSize = _MagazineSize;
		LaunchLocation = _LaunchLocation;
	};
}

struct FEnforcerWeaponEffectReloadParams
{
	UPROPERTY()
	float ReloadDuration;

	FEnforcerWeaponEffectReloadParams(float Duration)
	{
		ReloadDuration = Duration;
	}
}
