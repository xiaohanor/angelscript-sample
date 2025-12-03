class UPlayerEffortAudioSettings : UHazePlayerEffortAudioSettings
{
	// How quickly does the character become tired (out of breath)
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Global", meta = (Units = "times", Delta = 0.1))
	float ExertionFactor = 1.0;

	// How quickly does the character recover from exertion (catches their breath) - Global Multiplier
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Global", meta = (Units = "times", Delta = 0.1))
	float RecoveryFactor = 1.0;

	// How quickly does the character recover from exertion (catches their breath) - Low Intensity Multiplier
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Global", meta = (Units = "times", Delta = 0.1))
	float LowIntensityRecoveryFactor = 4;

	// How quickly does the character recover from exertion (catches their breath) - Medium Intensity Multiplier
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Global", meta = (Units = "times", Delta = 0.1))
	float MediumIntensityRecoveryFactor = 5;

	// How quickly does the character recover from exertion (catches their breath) - High Intensity Multiplier
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Global", meta = (Units = "times", Delta = 0.1))
	float HighIntensityRecoveryFactor = 6;

	// How quickly does the character recover from exertion (catches their breath) - Critical Intensity Multiplier
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Global", meta = (Units = "times", Delta = 0.1))
	float CriticalIntensityRecoveryFactor = 4;

	// Highest amount of exertion that Low efforts can build
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 1), Category = "Global")
	float LowEffortThreshold = 25.0;

	// The range of exertion up to which we consider our general intensity to be Low
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 1), Category = "Global")
	float LowIntensityRange = 25.0;

	// Highest amount of exertion that Medium efforts can build
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 1), Category = "Global")
	float MediumEffortThreshold = 60.0;

	// The range of exertion up to which we consider our general intensity to be Medium
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 1), Category = "Global")
	float MediumIntensityRange = 60.0;
	
	// Highest amount of exertion that High efforts can build
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 1), Category = "Global")
	float HighEffortThreshold = 80.0;

	// The range of exertion up to which we consider our general intensity to be High
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 1), Category = "Global")
	float HighIntensityRange = 80.0;
	
	// Highest amount of exertion that Critical efforts can build
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 1), Category = "Global")
	float CriticalEffortThreshold = 100.0;	

	// The range of exertion up to which we consider our general intensity to be Critical
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 1), Category = "Global")
	float CriticalIntensityRange = 100.0;

	// Effort curve multiplier when at zero exterion
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 0.1), Category = "Global")
	float EffortCurveMinMultiplier = 0.5;	

	// Effort curve multiplier when at max exterion clamped to intensity
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 0, UIMax = 100, Delta = 0.1), Category = "Global")
	float EffortCurveMaxMultiplier = 1.5;	

	// Multiplier applied to the amount of exertion that is generated when moving uphill
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 1, UIMax = 10), Category = "Global", meta = (Units = "times", Delta = 0.1))
	float SlopeTiltEffortMultiplier = 2.0;

	// The angle in degrees at which the the full SlopeTiltEffortMultiplier is applied
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, meta = (UIMin = 10, UIMax = 90), Category = "Global", meta = (Units = "deg", Delta = 0.1))
	float SlopeTiltMultiplierMaxAngle = 45.0;

	// Default curve that Low efforts are evaluated over. 0 = No exertion, 1 = Max exertion
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Default Curves", DisplayName = "Effort Curve")
	UCurveFloat EffortCurve;

	// Default curve that Low efforts are recovered over. 0 = Max exertion, 0 = No exertion
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Default Curves", DisplayName = "Recovery Curve")
	UCurveFloat RecoveryCurve;
}