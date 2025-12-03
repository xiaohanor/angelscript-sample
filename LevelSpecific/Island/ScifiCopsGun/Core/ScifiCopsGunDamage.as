
enum EScifiCopsGunDamageType
{
	Bullet,
	Throw,
	MAX
}


class UScifiCopsGunDamageSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Damage", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float ThrowDamage = 1.0;

	UPROPERTY(Category = "Damage", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float BulletDamage = 0.25;

	float GetDamage(EScifiCopsGunDamageType DamageType, float MaxHealth) const
	{
		if(DamageType == EScifiCopsGunDamageType::Bullet)
			return BulletDamage * MaxHealth;

		if(DamageType == EScifiCopsGunDamageType::Throw)
			return ThrowDamage * MaxHealth;

		return 0;
	}
}