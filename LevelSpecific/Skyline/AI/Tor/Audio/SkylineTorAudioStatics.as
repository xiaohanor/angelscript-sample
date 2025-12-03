namespace MrHammerAudio
{
	const uint BPM = 132;

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "1/4 Note Duration Seconds"))
	const float Get1_4DurationSeconds()
	{
		return 1.8181818181818181818181818181818;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "1/8 Note Duration Seconds"))
	const float Get1_8DurationSeconds()
	{
		return 0.90909090909090909090909090909091;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "1/16 Note Duration Seconds"))
	const float Get1_16DurationSeconds()
	{
		return 0.45454545454545454545454545454545;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "1/32 Note Duration Seconds"))
	const float Get1_32DurationSeconds()
	{
		return 0.22727272727272727272727272727273;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "1/64 Note Duration Seconds"))
	const float Get1_64DurationSeconds()
	{
		return 0.11363636363636363636363636363636;
	}
}