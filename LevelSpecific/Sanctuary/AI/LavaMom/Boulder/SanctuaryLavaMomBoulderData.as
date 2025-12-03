enum ESanctuaryLavaMomBoulderPattern
{
	Arrow = 0,
	V,
	SpiralShot,
	AntiSpiralShot,
	Cross,
	Circle
}

enum ESanctuaryLavaMomBoulderAngleSpace
{
	TowardsCentipedeMiddle = 0,
	ActorForward = 1,
	WorldSpace = 2,
}

USTRUCT()
struct FSanctuaryLavaMomBoulderPatternData
{
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	ESanctuaryLavaMomBoulderPattern PatternType;
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	ESanctuaryLavaMomBoulderAngleSpace AngleSpace;
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	int Amount = 3;
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	float AngleSpread = 30.0;
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	float Delay = 0.5;
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	float AngleOffset = 0.0;
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	float CurveToRight = 0.0;
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	bool bBigBoulder = false;
}

struct FSanctuaryLavaMomBoulderCreationData
{
	FSanctuaryLavaMomBoulderCreationData() {}
	FSanctuaryLavaMomBoulderCreationData(float Delay, float AnglyAngle = 0.0, ESanctuaryLavaMomBoulderAngleSpace Space = ESanctuaryLavaMomBoulderAngleSpace::TowardsCentipedeMiddle, float ProjectileCurveToRight = 0.0)
	{
		AngleSpace = Space;
		Angle = AnglyAngle;
		SpawnDelay = Delay;
		CurveToRight = ProjectileCurveToRight;
	}

	ESanctuaryLavaMomBoulderAngleSpace AngleSpace;
	float Angle = 0.0;
	float SpawnDelay = 0.0;
	float CurveToRight = 0.0;
	bool bBigBoulder = false;
}

struct FSanctuaryLavaMomMultiProjectileBoulderData
{
	FSanctuaryLavaMomBoulderCreationData SpawnData;
	bool bPrimed = false;
	bool bLaunched = false;
	float PrimeTimeStamp = 0.0;
	float LaunchTimeStamp = 0.0;
	ASanctuaryLavaMomBoulderProjectile ProjectileActor = nullptr;
	UBasicAIProjectileComponent Projectile = nullptr;
}