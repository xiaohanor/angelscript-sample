

enum EIslandNunchuckDamageType
{
	Light,
	Normal,
	Heavy,
}

struct FIslandNunchuckDamage
{
	EIslandNunchuckDamageType Type = EIslandNunchuckDamageType::Normal;
	float Multiplier = 1;
}

class UIslandNunchuckDamageSettings : UHazeComposableSettings
{
	// The percentage of the max health that will be removed
	UPROPERTY(Category = "Damage", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float Light = 0.25;

	// The percentage of the max health that will be removed
	UPROPERTY(Category = "Damage", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float Normal = 0.5;

	// The percentage of the max health that will be removed
	UPROPERTY(Category = "Damage", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float Heavy = 1.0;

	float GetDamage(FIslandNunchuckDamage DamageData, float MaxHealth) const
	{
		if(DamageData.Type == EIslandNunchuckDamageType::Normal)
			return Normal * DamageData.Multiplier * MaxHealth;

		if(DamageData.Type == EIslandNunchuckDamageType::Light)
			return Light * DamageData.Multiplier * MaxHealth;

		if(DamageData.Type == EIslandNunchuckDamageType::Heavy)
			return Heavy * DamageData.Multiplier * MaxHealth;

		return 0;
	}
}