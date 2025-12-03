struct FIslandBeamTurretronProjectileImpactParams
{
	FIslandBeamTurretronProjectileImpactParams(FVector Location)
	{
		HitLocation = Location;
	}

	UPROPERTY()
	FVector HitLocation;
}


struct FIslandBeamTurretronTelegraphingParams
{
	FIslandBeamTurretronTelegraphingParams(FVector InMuzzleLocation, FVector TurretLocation, UIslandBeamTurretronTrackingLaserComponent& LaserComp, UBasicAIProjectileLauncherComponent& _LauncherComp)
	{
		MuzzleLocation = InMuzzleLocation;
		TurretActorLocation = TurretLocation;
		TrackLaserComp = LaserComp;
		LauncherComp = _LauncherComp;
	}

	UPROPERTY()
	FVector MuzzleLocation;
	
	UPROPERTY()
	FVector TurretActorLocation;

	UPROPERTY()
	UIslandBeamTurretronTrackingLaserComponent TrackLaserComp;
	
	UPROPERTY()
	UBasicAIProjectileLauncherComponent LauncherComp;
}

struct FIslandBeamTurretronOnDeathParams
{
	FIslandBeamTurretronOnDeathParams(AHazePlayerCharacter Player = nullptr)
	{
		LastAttacker = Player;
	}

	UPROPERTY()
	AHazePlayerCharacter LastAttacker;
}


UCLASS(Abstract)
class UIslandBeamTurretronEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath(FIslandBeamTurretronOnDeathParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage(FIslandBeamTurretronProjectileImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphingTrackingLaser(FIslandBeamTurretronTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphing(FIslandBeamTurretronTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraphing() {}
}