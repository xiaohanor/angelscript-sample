struct FCoastBossAeuronauticPlayerShieldData
{
	UPROPERTY(BlueprintReadOnly)
	ECoastBossPlayerDroneShield State;
}

struct FCoastBossAeuronauticPlayerReceiveDamageData
{
	UPROPERTY(BlueprintReadOnly)
	ECoastBossAeuronauticPlayerReceiveDamageType DamageType;
}

struct FCoastBossAeuronauticBossReceiveDamageData
{
	UPROPERTY(BlueprintReadOnly)
	ECoastBossAeuronauticBossReceiveDamageType DamageType = ECoastBossAeuronauticBossReceiveDamageType::NormalProjectile;
}

struct FCoastBossAeronauticPlayerDiedEffectData
{
	UPROPERTY()
	USceneComponent PlaneToAttachTo;

	UPROPERTY()
	AHazePlayerCharacter Player;
}

struct FCoastBossAeronauticDashEffectData
{
	UPROPERTY()
	USceneComponent PlaneToAttachTo;

	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	ACoastBossPlayerDrone Drone;
}

struct FCoastBossAeronauticPowerupEffectData
{
	UPROPERTY()
	ECoastBossPlayerPowerUpType PowerupType;
}

enum ECoastBossAeuronauticPlayerReceiveDamageType
{
	Bullet,
	MillZap,
	MineExplosion,
	DroneCollision,
}

enum ECoastBossAeuronauticBossReceiveDamageType
{
	NormalProjectile,
	BarrageProjectile,
	HomingProjectile,
	Laser,
}

UCLASS(Abstract)
class UCoastBossAeuronauticPlayerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ShieldChangeState(FCoastBossAeuronauticPlayerShieldData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GotImpacted(FCoastBossAeuronauticPlayerReceiveDamageData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerLaserActivated(FCoastBossPlayerBulletOnShootParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootBasicProjectile(FCoastBossPlayerBulletOnShootParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootBarrageProjectile(FCoastBossPlayerBulletOnShootParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootHomingProjectile(FCoastBossPlayerBulletOnShootParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerProjectileImpactBoss(FCoastBossAeuronauticBossReceiveDamageData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Died(FCoastBossAeronauticPlayerDiedEffectData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GotImpactDuringInvulnerable() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDash(FCoastBossAeronauticDashEffectData Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPickupPowerup(FCoastBossAeronauticPowerupEffectData Params) {}
}