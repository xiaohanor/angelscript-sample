// structural friends of accelerateds :3
enum EEasing
{
	EaseInOut,
	EaseIn,
	EaseOut,
	SineInOut,
	SineIn,
	SineOut,
	Linear,
}

struct FHazeEasedFloat
{
	private float EaseStartValue = 0.0;
	private float EaseTargetValue = 1.0;
	
	private float EaseProgression = 0.0;
	private float EaseDuration = 1.0;
	private EEasing EaseType = EEasing::EaseInOut;
	private int EaseIntExponent = 2;
	private float EaseFloatExponent = 2.0;
	private bool bEasedReversed = false;

	void EaseTo(float StartValue, float TargetValue, float Duration, float DeltaTime, EEasing Type = EEasing::EaseInOut, int Exponent = 2, bool bReverse = false)
	{
		ResetIfNeccessary(StartValue, TargetValue, Duration, Type, Exponent, bReverse);
		EaseProgression = EaseProgression + DeltaTime;
	}

	void ForceResetProgress()
	{
		EaseProgression = 0.0;
	}

	private void ResetIfNeccessary(float StartValue, float TargetValue, float Duration, EEasing Type, int Exponent, bool bReverse = false)
	{
		bool bSameArguments = Math::IsNearlyEqual(StartValue, EaseStartValue, KINDA_SMALL_NUMBER);
		bSameArguments = bSameArguments && Math::IsNearlyEqual(TargetValue, EaseTargetValue, KINDA_SMALL_NUMBER);
		bSameArguments = bSameArguments && Math::IsNearlyEqual(Duration, EaseDuration, KINDA_SMALL_NUMBER);
		bSameArguments = bSameArguments && Type == EaseType;
		bSameArguments = bSameArguments && Exponent == EaseIntExponent;
		bSameArguments = bSameArguments && bReverse == bEasedReversed;
		if (!bSameArguments)
		{
			bEasedReversed = bReverse;
			EaseStartValue = StartValue;
			EaseTargetValue = TargetValue;
			EaseProgression = 0.0;
			EaseDuration = Duration;
			EaseType = Type;
			EaseIntExponent = Exponent;
			EaseFloatExponent = float(EaseIntExponent);
		}
	}

	float GetValue() const
	{
		float Alpha = 1.0;
		if (!Math::IsNearlyEqual(EaseDuration, 0.0, KINDA_SMALL_NUMBER))
			Alpha = Math::Saturate(EaseProgression / EaseDuration);
		if (bEasedReversed)
			Alpha = 1.0 - Alpha;
		switch (EaseType)
		{
			case EEasing::EaseInOut:
				return Math::EaseInOut(EaseStartValue, EaseTargetValue, Alpha, EaseFloatExponent);
			case EEasing::EaseIn:
				return Math::EaseIn(EaseStartValue, EaseTargetValue, Alpha, EaseFloatExponent);
			case EEasing::EaseOut:
				return Math::EaseOut(EaseStartValue, EaseTargetValue, Alpha, EaseFloatExponent);
			case EEasing::SineInOut:
				return Math::SinusoidalInOut(EaseStartValue, EaseTargetValue, Alpha);
			case EEasing::SineIn:
				return Math::SinusoidalIn(EaseStartValue, EaseTargetValue, Alpha);
			case EEasing::SineOut:
				return Math::SinusoidalOut(EaseStartValue, EaseTargetValue, Alpha);
			case EEasing::Linear:
				return Math::Lerp(EaseStartValue, EaseTargetValue, Alpha);
		}
	}
}

struct FHazeEasedVector
{
	private FHazeEasedFloat AlphaEasings;
	private FVector StartVector;
	private FVector TargetVector;

	void EaseTo(FVector StartValue, FVector TargetValue, float Duration, float DeltaTime, EEasing Type = EEasing::EaseInOut, int Exponent = 2, bool bReverse = false)
	{
		if (StartValue.DistSquared(StartVector) > KINDA_SMALL_NUMBER || TargetValue.DistSquared(TargetVector) > KINDA_SMALL_NUMBER)
		{
			StartVector = StartValue;
			TargetVector = TargetValue;
			AlphaEasings.ForceResetProgress();
		}
		AlphaEasings.EaseTo(0.0, 1.0, Duration, DeltaTime, Type, Exponent, bReverse);
	}

	void ForceResetProgress()
	{
		AlphaEasings.ForceResetProgress();
	}

	FVector GetValue() const
	{
		float EasedAlpha = AlphaEasings.GetValue();
		return Math::Lerp(StartVector, TargetVector, EasedAlpha);
	}
}

struct FHazeEasedQuat
{
	private FHazeEasedFloat AlphaEasings;
	private FQuat StartQuat;
	private FQuat TargetQuat;

	void EaseTo(FQuat StartValue, FQuat TargetValue, float Duration, float DeltaTime, EEasing Type = EEasing::EaseInOut, int Exponent = 2, bool bReverse = false)
	{
		if (!StartValue.Equals(StartQuat) || !TargetValue.Equals(TargetQuat))
		{
			StartQuat = StartValue;
			TargetQuat = TargetValue;
			AlphaEasings.ForceResetProgress();
		}
		AlphaEasings.EaseTo(0.0, 1.0, Duration, DeltaTime, Type, Exponent, bReverse);
	}

	void ForceResetProgress()
	{
		AlphaEasings.ForceResetProgress();
	}

	FQuat GetValue() const
	{
		float EasedAlpha = AlphaEasings.GetValue();
		return FQuat::Slerp(StartQuat, TargetQuat,EasedAlpha);
	}
}