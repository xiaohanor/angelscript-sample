struct FIslandTurretronProjectileImpactPlayerEventParams
{
	FIslandTurretronProjectileImpactPlayerEventParams(FVector Location, AHazeActor OwnerTurretron, AHazePlayerCharacter Player = nullptr)
	{
		HitLocation = Location;
		Turretron = Cast<AAIIslandTurretron>(OwnerTurretron);
		LastAttacker = Player;
	}

	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	AAIIslandTurretron Turretron;

	UPROPERTY()
	AHazePlayerCharacter LastAttacker;
}

struct FIslandTurretronOnDeathPlayerEventParams
{
	FIslandTurretronOnDeathPlayerEventParams(AHazeActor OwnerTurretron, AHazePlayerCharacter Player = nullptr)
	{
		Turretron = Cast<AAIIslandTurretron>(OwnerTurretron);
		LastAttacker = Player;
	}

	UPROPERTY()
	AAIIslandTurretron Turretron;

	UPROPERTY()
	AHazePlayerCharacter LastAttacker;
}

UCLASS(Abstract)
class UIslandTurretronPlayerEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath(FIslandTurretronOnDeathPlayerEventParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage(FIslandTurretronProjectileImpactPlayerEventParams Params) {}
}