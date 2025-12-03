// struct FIslandNunchuckEpiCenterData
// {
// 	/** How long the epicenter will stay at the current location until reset triggers */
// 	UPROPERTY(Category = "Melee|Target|Epicenter")
// 	float KeepEpicenterTime = 2.0;

// 	/** Target range while inside the epicenter */
// 	UPROPERTY(Category = "Melee|Target|Epicenter")
// 	FIslandNunchuckPercentageOrValueData MaxTargetRange;

// 	/** Depending on the MaxTargetRange, this is the max score that can be given */
// 	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1000.0"))
// 	float DistanceScore = 100.0;

// 	/** In the middle of the camera is 0 degrees */
// 	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "180.0"))
// 	float MaxCameraAngle = 180.0;

// 	/** If true, and the target is outside the max camera angle, the target is not valid, else it will not add the camera angle score */
// 	UPROPERTY()
// 	bool bOutsideMaxCameraAngleIsInvalid = false;

// 	/** Depending on the max camera angle, this is the max score that can be added */
// 	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1000.0"))
// 	float CameraAngleScore = 100.0;

// 	/** Steering towards the target is 0 degrees */
// 	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "180.0"))
// 	float MaxInputAngle = 180.0;

// 	/** If true, and the target is outside the max input angle, the target is not valid, else it will not add the input angle score */
// 	UPROPERTY()
// 	bool bOutsideMaxInputAngleIsInvalid = false;

// 	/** Depening on the max input angle, this is the max score that can be given */
// 	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1000.0"))
// 	float InputScore = 100.0;

// 	/** The more inverted from the previous target direct, the more of the score */
// 	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1000.0"))
// 	float LastTargetDirectionInvertScore = 100.0;

// 	/** The longer it was since we where a target, the more score */
// 	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1000.0"))
// 	float TimeScore = 100.0;

// 	/** Max time until 'TimeScore' hits max */
// 	UPROPERTY()
// 	float TimeScoreMaxTime = 3.0;

// 	// Only used by internal calculations
// 	float InternalBonusScore = 0;
// }


// struct FIslandNunchuckActionEpiCenter
// {
// 	private bool bIsValid = false;
// 	float InvalidTime = 0.0;
// 	FVector CurrentLocation = FVector::ZeroVector;
// 	FVector CreationLocation = FVector::ZeroVector;

// 	bool IsValid() const
// 	{
// 		return bIsValid;
// 	}

// 	void Enable(FVector Location, bool bForce = false)
// 	{
// 		if(!bForce && bIsValid)
// 		{
// 			InvalidTime = 0;
// 			return;
// 		}

// 		bIsValid = true;
// 		CreationLocation = Location;
// 		CurrentLocation = Location;
// 		InvalidTime = 0;
// 	}

// 	void Invalidate()
// 	{
// 		bIsValid = false;
// 	}
// }