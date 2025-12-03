struct FIslandTurretronProjectileImpactParams
{
	FIslandTurretronProjectileImpactParams(FVector Location)
	{
		HitLocation = Location;
	}

	UPROPERTY()
	FVector HitLocation;
}

struct FIslandTurretronTelegraphingParams
{
	FIslandTurretronTelegraphingParams(USceneComponent Left, USceneComponent Right, FVector TurretLocation)
	{
		MuzzleLeft = Left;
		MuzzleRight = Right;
		TurretActorLocation = TurretLocation;
	}

	UPROPERTY()
	USceneComponent MuzzleLeft;
	
	UPROPERTY()
	USceneComponent MuzzleRight;
	
	UPROPERTY()
	FVector TurretActorLocation;
}

struct FIslandTurretronOnDeathParams
{
	FIslandTurretronOnDeathParams(AHazePlayerCharacter Player = nullptr)
	{
		LastAttacker = Player;
	}

	UPROPERTY()
	AHazePlayerCharacter LastAttacker;
}


UCLASS(Abstract)
class UIslandTurretronEffectHandler : UHazeEffectEventHandler
{
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDeath(FIslandTurretronOnDeathParams Params) {}

    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnDamage(FIslandTurretronProjectileImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphing(FIslandTurretronTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraphing() {}
}