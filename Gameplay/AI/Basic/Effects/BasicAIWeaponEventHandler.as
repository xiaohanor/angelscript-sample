UCLASS(Abstract)
class UBasicAIWeaponEventHandler : UHazeEffectEventHandler
{
	// Triggered when we're about to start launching projectiles
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphShooting(FWeaponHandlingTelegraphParams Params){};

	// Triggered for every projectile which is launched
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShotFired(FWeaponHandlingLaunchParams Params){};

	// Triggered when starting to reload
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReload(FWeaponHandlingReloadParams Params){};

	// Triggered when finished reloading
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReloadComplete(){};
};


struct FWeaponHandlingTelegraphParams
{
	UPROPERTY()
	UBasicAIProjectileLauncherComponentBase Weapon;

	UPROPERTY()
	float TelegraphDuration = 1.0;

	FWeaponHandlingTelegraphParams(UBasicAIProjectileLauncherComponentBase Launcher, float Duration)
	{
		Weapon = Launcher;
		TelegraphDuration = Duration;	
	}

	FWeaponHandlingTelegraphParams(float Duration)
	{
		Weapon = nullptr;
		TelegraphDuration = Duration;	
	}
}

struct FWeaponHandlingLaunchParams
{
	UPROPERTY()
	UBasicAIProjectileLauncherComponentBase Weapon;

	UPROPERTY()
	FVector LaunchLocation;

	UPROPERTY()
	FVector LaunchVelocity;

	UPROPERTY()
	int NumShotsFired = 0;

	UPROPERTY()
	int MagazineSize = 0;

	FWeaponHandlingLaunchParams(UBasicAIProjectileLauncherComponentBase Launcher, int NumberOfShotsFired, int NumberOfShotsInMagazine = MAX_int32)
	{
		Weapon = Launcher;
		LaunchLocation = Launcher.LaunchLocation;
		LaunchVelocity = FVector::ZeroVector;
		if (Launcher.LastLaunchedProjectile != nullptr)
		{
			LaunchLocation = Launcher.LastLaunchedProjectile.Owner.ActorLocation;
			LaunchVelocity = Launcher.LastLaunchedProjectile.Velocity;
		}

		NumShotsFired = NumberOfShotsFired;
		MagazineSize = NumberOfShotsInMagazine;
	}

	FWeaponHandlingLaunchParams(FVector Location, FVector Velocity, int NumberOfShotsFired, int NumberOfShotsInMagazine = MAX_int32)
	{
		Weapon = nullptr;
		LaunchLocation = Location;
		LaunchVelocity = Velocity;
		NumShotsFired = NumberOfShotsFired;
		MagazineSize = NumberOfShotsInMagazine;
	}
}

struct FWeaponHandlingReloadParams
{
	UPROPERTY()
	UBasicAIProjectileLauncherComponent Weapon;

	UPROPERTY()
	float ReloadDuration = 1.0;

	FWeaponHandlingReloadParams(UBasicAIProjectileLauncherComponent Launcher, float Duration)
	{
		Weapon = Launcher;
		ReloadDuration = Duration;	
	}
}
