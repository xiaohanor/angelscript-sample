// Mimics FHazeCameraSettings
// Eman TODO: Handle additive settings
USTRUCT()
struct FBlendSplineKeyCameraSettings
{
	// Field of view
	UPROPERTY(EditAnywhere, Category = "FOV")
	bool bUseFOV = false;

	UPROPERTY(EditAnywhere, Category = "FOV", meta = (EditCondition = "bUseFOV"))
	float FOV = 70;


	// Sensitivity Multiplier
	UPROPERTY(EditAnywhere, Category = "Input")
	bool bUseSensitivityFactor = false;

	UPROPERTY(EditAnywhere, Category = "Input", meta = (EditCondition = "bUseSensitivityFactor"))
	float SensitivityFactor = 1;

	UPROPERTY(EditAnywhere, Category = "Input", meta = (EditCondition = "bUseSensitivityFactor"))
	float SensitivityFactorYaw = 1;

	UPROPERTY(EditAnywhere, Category = "Input", meta = (EditCondition = "bUseSensitivityFactor"))
	float SensitivityFactorPitch = 1;
}

USTRUCT()
struct FBlendSplineKeyCameraClampSettings
{
	UPROPERTY(EditAnywhere)
	bool bUseClampSettings = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseClampSettings"))
	FHazeCameraClampSettings Settings;
}

USTRUCT()
struct FFocusCameraBlendSplineKeyInfo
{
	UFocusCameraBlendSplineKey PreviousKey;
	UFocusCameraBlendSplineKey NextKey;

	float PlayerDistanceAlongSpline;

	// Where are we between both points (fraction)
	float Alpha;
	
	bool IsValidRange() const
	{
		return PreviousKey != nullptr && NextKey != nullptr;
	}
}

asset SegmentedSplineFocusCameraBlendSheet of UHazeCapabilitySheet
{
	AddCapability(n"SplineFocusCameraBlendCapability");
	Components.Add(USplineFocusCameraBlendPlayerComponent);
}