class UFitnessSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "General")
	bool RespectPriorityTarget = true;

	UPROPERTY(Category = "General")
	float AdditionalOptimalFitness = 0.0;

	// A fitness value above this is considered to be optimal
	UPROPERTY(Category = "Threshold")
	float OptimalThresholdMax = 2.0;

	// A fitness value below this should be ignored when considering fitness
	UPROPERTY(Category = "Threshold")
	float OptimalThresholdMin = 1.0;

	// How long the user should be in optimal fitness to achieve a maximum fitness score multiplier
	UPROPERTY(Category = "Multiplier")
	float ReachMaxMultiplierDuration = 1.0;
}
