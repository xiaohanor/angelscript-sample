class UBalancingSettings : UHazeComposableSettings
{
	// At these health factors we reduce tokens by the set amount - only the token reduction mount at each factor will be reduced (and not done in addition to previous factors)
	UPROPERTY(Category = "Tokens")
	TArray<FBalancingSettingsTokenReductionHealthLimit> TokenReductionHealthLimitFactors;
	default TokenReductionHealthLimitFactors.Add(FBalancingSettingsTokenReductionHealthLimit(0.1, 1));
}

struct FBalancingSettingsTokenReductionHealthLimit
{
	FBalancingSettingsTokenReductionHealthLimit(float InHealthFactor, int InRemoveTokens)
	{
		HealthFactor = InHealthFactor;
		RemoveTokens = InRemoveTokens;
	}

	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float HealthFactor = 1.0;

	UPROPERTY()
	int RemoveTokens = 1;
}