enum ESanctuaryGrimbeastBoulderPattern
{
	Arrow = 0,
	V,
	SpiralShot,
	AntiSpiralShot,
	Cross,
	Circle
}

enum ESanctuaryGrimbeastBoulderAngleSpace
{
	TowardsCentipedeMiddle = 0,
	ActorForward = 1,
	WorldSpace = 2,
}

USTRUCT()
struct FSanctuaryGrimbeastBoulderPatternData
{
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	ESanctuaryGrimbeastBoulderPattern PatternType;
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	ESanctuaryGrimbeastBoulderAngleSpace AngleSpace;
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
}

struct FSanctuaryGrimbeastBoulderCreationData
{
	FSanctuaryGrimbeastBoulderCreationData() {}
	FSanctuaryGrimbeastBoulderCreationData(float Delay, float AnglyAngle = 0.0, ESanctuaryGrimbeastBoulderAngleSpace Space = ESanctuaryGrimbeastBoulderAngleSpace::TowardsCentipedeMiddle, float ProjectileCurveToRight = 0.0)
	{
		AngleSpace = Space;
		Angle = AnglyAngle;
		SpawnDelay = Delay;
		CurveToRight = ProjectileCurveToRight;
	}

	ESanctuaryGrimbeastBoulderAngleSpace AngleSpace;
	float Angle = 0.0;
	float SpawnDelay = 0.0;
	float CurveToRight = 0.0;
}

struct FSanctuaryGrimbeastMultiProjectileBoulderData
{
	FSanctuaryGrimbeastBoulderCreationData SpawnData;
	bool bPrimed = false;
	bool bLaunched = false;
	float PrimeTimeStamp = 0.0;
	float LaunchTimeStamp = 0.0;
	UBasicAIProjectileComponent Projectile = nullptr;
}