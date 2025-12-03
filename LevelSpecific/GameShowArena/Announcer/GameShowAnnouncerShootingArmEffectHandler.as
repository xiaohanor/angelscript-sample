UCLASS(Abstract)
class UGameShowAnnouncerShootingArmEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Shoot(FGameShowArenaShootingArmData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ProjectileHit(FGameShowArenaShootingArmProjectileData Data) {}
};

struct FGameShowArenaShootingArmData
{
	UPROPERTY()
	AGameShowAnnouncerShootingArm GameShowAnnouncerShootingArm; 
}

struct FGameShowArenaShootingArmProjectileData
{
	UPROPERTY()
	AGameShowArenaTurretProjectile GameShowArenaTurretProjectile; 
}