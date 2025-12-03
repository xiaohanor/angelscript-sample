namespace AlphaStatics
{
	float LinearToSawtooth(float LinearAlpha)
	{
		//     o
		//   o   o
		// o       o
		if (LinearAlpha <= 0.5)
			return LinearAlpha * 2.0;
		return Math::GetMappedRangeValueClamped(FVector2D(0.5, 1.0), FVector2D(1.0, 0.0), LinearAlpha);
	}

	// What's the Frequency Alpha, Kenneth?
	float FrequencyAlpha(float Value, float Frequency = 1.0)
	{
		return (Math::Sin(Value * Frequency * 2.0 * PI - 0.5 * PI) + 1.0) * 0.5;
	}
}