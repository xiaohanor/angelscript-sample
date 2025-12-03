enum ESanctuaryLavamoleBoulderPattern
{
	Arrow = 0,
	V,
	SpiralShot,
	AntiSpiralShot,
	Cross,
	Circle
}

enum ESanctuaryLavamoleBoulderAngleSpace
{
	TowardsCentipedeMiddle = 0,
	ActorForward = 1,
	WorldSpace = 2,
}

USTRUCT()
struct FSanctuaryLavamoleBoulderPatternData
{
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	ESanctuaryLavamoleBoulderPattern PatternType;
	UPROPERTY(EditAnywhere, Category = "Shoot Pattern Data")
	ESanctuaryLavamoleBoulderAngleSpace AngleSpace;
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

struct FSanctuaryLavamoleBoulderCreationData
{
	FSanctuaryLavamoleBoulderCreationData() {}
	FSanctuaryLavamoleBoulderCreationData(float Delay, float AnglyAngle = 0.0, ESanctuaryLavamoleBoulderAngleSpace Space = ESanctuaryLavamoleBoulderAngleSpace::TowardsCentipedeMiddle, float ProjectileCurveToRight = 0.0)
	{
		AngleSpace = Space;
		Angle = AnglyAngle;
		SpawnDelay = Delay;
		CurveToRight = ProjectileCurveToRight;
	}

	ESanctuaryLavamoleBoulderAngleSpace AngleSpace;
	float Angle = 0.0;
	float SpawnDelay = 0.0;
	float CurveToRight = 0.0;
}

class USanctuaryLavamoleMultiBoulderComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Shoot Pattern")
	private TArray<FSanctuaryLavamoleBoulderPatternData> ShootPattern;
	default ShootPattern.Add(FSanctuaryLavamoleBoulderPatternData());

	private int CurrentShootPatternIndex = 0;

	UFUNCTION()
	void AssignShootPattern(FSanctuaryLavamoleBoulderPatternData NewShootPattern)
	{
		ShootPattern.Empty();
		CurrentShootPatternIndex = 0; 
		ShootPattern.Add(NewShootPattern);
	}

	void GetNextShootPattern(TArray<FSanctuaryLavamoleBoulderCreationData>& OutData)
	{
		if (!ensure(ShootPattern.Num() > 0, "No shoot patterns in mole!"))
			return;

		GetShootDataFromPattern(OutData, ShootPattern[CurrentShootPatternIndex]);
		CurrentShootPatternIndex++;
		if (CurrentShootPatternIndex >= ShootPattern.Num())
			CurrentShootPatternIndex = 0;
	}
	
	private void GetShootDataFromPattern(TArray<FSanctuaryLavamoleBoulderCreationData>& OutData, const FSanctuaryLavamoleBoulderPatternData& PatternData)
	{
		OutData.Empty();
		if (PatternData.Amount == 0)
			return;

		if (PatternData.Amount == 1)
		{
			OutData.Add(FSanctuaryLavamoleBoulderCreationData(PatternData.Delay));
		}
		else 
		{
			switch (PatternData.PatternType)
			{
				case ESanctuaryLavamoleBoulderPattern::Arrow:
					CreateArrowShot(OutData, PatternData.Amount, PatternData.Delay, PatternData.AngleSpread, false);
					break;
				case ESanctuaryLavamoleBoulderPattern::V:
					CreateArrowShot(OutData, PatternData.Amount, PatternData.Delay, PatternData.AngleSpread, true);
					break;
				case ESanctuaryLavamoleBoulderPattern::SpiralShot:
					CreateSpiralShot(OutData, PatternData.Amount, PatternData.Delay, PatternData.AngleSpread);
					break;
				case ESanctuaryLavamoleBoulderPattern::AntiSpiralShot:
					CreateSpiralShot(OutData, PatternData.Amount, PatternData.Delay, -PatternData.AngleSpread);
					break;
				case ESanctuaryLavamoleBoulderPattern::Cross:
				{
					int CrossWaves = Math::IntegerDivisionTrunc(PatternData.Amount, 4);
					for (int i = 0; i < CrossWaves; ++i)
						CreateCircleShot(OutData, 4, i * PatternData.Delay, 360.0);
					break;
				}
				case ESanctuaryLavamoleBoulderPattern::Circle:
					CreateCircleShot(OutData, PatternData.Amount, PatternData.Delay, 360.0);
					break;
				default: // single shot
				{
	#if EDITOR
					PrintToScreen("Lava Mole Pattern not found! Defaulting to single", 1.0, FLinearColor::Red);
	#endif
					OutData.Add(FSanctuaryLavamoleBoulderCreationData(PatternData.Delay));
				}
			}
		}

		for (FSanctuaryLavamoleBoulderCreationData& CreationData : OutData)
		{
			CreationData.AngleSpace = PatternData.AngleSpace;
			CreationData.CurveToRight = PatternData.CurveToRight;
			CreationData.Angle += PatternData.AngleOffset;
		}
	}

	private void CreateArrowShot(TArray<FSanctuaryLavamoleBoulderCreationData>& OutData, int Amount, float Delay, float TotalAngle, bool bIsVShape)
	{
		const float AngleStep = TotalAngle / (Amount -1);
		const float HalfCone = TotalAngle / 2;
		const int HalfAmount = Math::IntegerDivisionTrunc(Amount, 2);
		bool bHasEvenNumberOfShots = Amount % 2 == 0;
		for (int i = 0; i < Amount; ++i)
		{
			const float CurrentAngle = (AngleStep * i) - HalfCone;
			int ShapeDelayUnAbsed = i - HalfAmount;
			int ShapeDelay = Math::Abs(ShapeDelayUnAbsed);
			if (bHasEvenNumberOfShots && i < HalfAmount)
				ShapeDelay -= 1;
			if (bIsVShape)
				ShapeDelay = HalfAmount - ShapeDelay;

			OutData.Add(FSanctuaryLavamoleBoulderCreationData(ShapeDelay * Delay, CurrentAngle));
		}
	}

	private void CreateSpiralShot(TArray<FSanctuaryLavamoleBoulderCreationData>& OutData, int Amount, float Delay, float TotalAngle)
	{
		const float AngleStep = TotalAngle / (Amount -1);
		for (int i = 0; i < Amount; ++i)
			OutData.Add(FSanctuaryLavamoleBoulderCreationData(Delay * i, AngleStep * i));
	}

	private void CreateCircleShot(TArray<FSanctuaryLavamoleBoulderCreationData>& OutData, int Amount, float Delay, float TotalAngle, bool bDelayEven = false)
	{
		const float AngleStep = TotalAngle / Amount;
		for (int i = 0; i < Amount; ++i)
		{
			int DelayEven = 0;
			if (bDelayEven)
				DelayEven = i % 2;
			OutData.Add(FSanctuaryLavamoleBoulderCreationData(DelayEven * Delay, AngleStep * i));
		}
	}
};