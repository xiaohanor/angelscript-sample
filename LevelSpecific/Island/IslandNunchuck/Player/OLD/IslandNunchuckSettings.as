

// class UPlayerIslandNunchuckUserSettings : UDataAsset
// {
// 	// /** How long it will take to reach the target at max distance */
// 	// UPROPERTY(Category = "Melee|Target")
// 	// float DefaultReachTargetTime = 0.3;

// 	/** How far away from the target, we can lock on
// 	 * OBS! can be overridden by each target component instance
// 	 */
// 	UPROPERTY(Category = "Melee|Target")
// 	float DefaultReachTargetRange = 150.0;
	
// 	/** Tweaks the ReachTargetRange depending on the players movement velocity
// 	 * Time is the velocity of the player, Value is the multiplier 
// 	 */
// 	UPROPERTY(Category = "Melee|Target")
// 	FRuntimeFloatCurve ReachTargetRangeBasedOnVelocityModifer;

// 	/** If true, the value from the curve is applied as a multiplier to the range, else, its added. */
// 	UPROPERTY(Category = "Melee|Target")
// 	bool bReachTargetRangeBasedOnVelocityModiferIsPercentage = false;

// 	/** If the player is moving away from the target with this amount of speed, the 'MoveAwayFromTargetRangeModifier' will kick in
// 	 * Unused if <0
// 	 */
// 	UPROPERTY(Category = "Melee|Target")
// 	float MinTriggerMoveAwayFromTargetSpeed = -1;

// 	/** Time; How much you are moving away from the target (0 -> 1)
// 	 *  Value; the multiplier to the calculated range
// 	 */
// 	UPROPERTY(Category = "Melee|Target", meta = (EditCondition = "MinTriggerMoveAwayFromTargetSpeed >= 0"))
// 	FRuntimeFloatCurve MoveAwayFromTargetRangeModifier;
// 	//default MoveAwayFromTargetRangeModifier.AddDefaultKey(0.0, 1.0);
// 	//default MoveAwayFromTargetRangeModifier.AddDefaultKey(1.0, 0.0);

// 	/** Modifiers for how far you will be able to reach a target, based on the current move type */
// 	UPROPERTY(Category = "Melee|Target", EditFixedSize, Meta = (ArraySizeEnum = "/Script/Angelscript.EPlayerScifiMeleeMoveType"))
// 	TArray<FScifiMeleePercentageOrValueData> ReachTargetRangeModifiers;
// 	default ReachTargetRangeModifiers.SetNum(EPlayerScifiMeleeMoveType::MAX);
// 	default ReachTargetRangeModifiers[int(EPlayerScifiMeleeMoveType::Standard)] = FScifiMeleePercentageOrValueData(400.0);
// 	default ReachTargetRangeModifiers[int(EPlayerScifiMeleeMoveType::Sprint)] = FScifiMeleePercentageOrValueData(400.0);
// 	default ReachTargetRangeModifiers[int(EPlayerScifiMeleeMoveType::Dash)] = FScifiMeleePercentageOrValueData(400.0);
// 	default ReachTargetRangeModifiers[int(EPlayerScifiMeleeMoveType::Slide)] = FScifiMeleePercentageOrValueData(400.0);
// 	default ReachTargetRangeModifiers[int(EPlayerScifiMeleeMoveType::InAir)] = FScifiMeleePercentageOrValueData(600.0);


// 	/** Depending on the MaxTargetRange, this is the max score that can be given */
// 	UPROPERTY(Category = "Melee|Target", meta = (ClampMin = "0.0", ClampMax = "1000.0"))
// 	float DistanceScore = 100.0;

// 	/** In the middle of the camera is 0 degrees */
// 	UPROPERTY(Category = "Melee|Target", meta = (ClampMin = "0.0", ClampMax = "180.0"))
// 	float MaxCameraAngle = 180.0;

// 	/** If true, and the target is outside the max camera angle, the target is not valid, else it will not add the camera angle score */
// 	UPROPERTY(Category = "Melee|Target")
// 	bool bOutsideMaxCameraAngleIsInvalid = false;

// 	/** Depending on the max camera angle, this is the max score that can be added */
// 	UPROPERTY(Category = "Melee|Target", meta = (ClampMin = "0.0", ClampMax = "1000.0"))
// 	float CameraAngleScore = 100.0;

// 	/** Steering towards the target is 0 degrees */
// 	UPROPERTY(Category = "Melee|Target", meta = (ClampMin = "0.0", ClampMax = "180.0"))
// 	float MaxInputAngle = 180.0;

// 	/** If true, and the target is outside the max input angle, the target is not valid, else it will not add the input angle score */
// 	UPROPERTY(Category = "Melee|Target")
// 	bool bOutsideMaxInputAngleIsInvalid = false;

// 	/** Depening on the max input angle, this is the max score that can be given */
// 	UPROPERTY(Category = "Melee|Target", meta = (ClampMin = "0.0", ClampMax = "1000.0"))
// 	float InputScore = 100.0;

// 	// /** How long the epicenter will stay at the current location until reset triggers */
// 	// UPROPERTY(Category = "Melee|Target|Epicenter")
// 	// float KeepEpicenterTime = 2.0;

// 	// /** Target range while inside the epicenter */
// 	// UPROPERTY(Category = "Melee|Target|Epicenter")
// 	// FScifiMeleePercentageOrValueData InsideEpiCenterReachTargetRange;

// 	// /** How much the epicenter can move away from where it was created when giving input.
// 	//  * Only used if >= 0
// 	//  */
// 	// UPROPERTY(Category = "Melee|Target|Epicenter")
// 	// float MaxEpicenterMoveDistance = -1;

// 	// /** How fast the epicenter moves when giving input */
// 	// UPROPERTY(Category = "Melee|Target|Epicenter")
// 	// float EpicenterMovespeed = 100.0;

// 	UPROPERTY(Category = "Melee|Target|Epicenter")
// 	TArray<FIslandNunchuckEpiCenterData> EpiCenterRangeData;

// 	// How fast the epicenter will move towards the player
// 	UPROPERTY(Category = "Melee|Target|Epicenter")
// 	float EpicenterMoveSpeed = 100.0;

// 	// /** 
// 	//  * We can choose to give more score to the input based on the distance to the target
// 	//  * @Time; Distance from the epicenter
// 	//  * @Value; The 'TargetInputTowardsScore' is multiplied with this
// 	//  */
// 	// UPROPERTY(Category = "Melee|Target|Score")
// 	// FRuntimeFloatCurve TargetInputTowardsScoreMultiplierBasedOnDistance;


// 	/** The factor of time dilation when hitting a target */
// 	UPROPERTY(Category = "Melee|HitStop")
// 	float HitStopDilation = 0.05;

// 	/** How long should hit stop last when hitting a target */
// 	UPROPERTY(Category = "Melee|HitStop")
// 	float HitStopDuration = 0.05;

// 	/** How long should we blend in and out to hit stop dilation */
// 	UPROPERTY(Category = "Melee|HitStop")
// 	float HitStopBlendDuration = 0.0125;

// 	bool GetEpicenterData(float Range, float DefaultRange, FIslandNunchuckEpiCenterData& Out) const
// 	{
// 		int FoundIndex = -1;
// 		float ClosestDiff = MAX_flt;
// 		for(int i = 0; i < EpiCenterRangeData.Num(); ++i)
// 		{
// 			float MaxRange = EpiCenterRangeData[i].MaxTargetRange.GetFinalizedValue(DefaultRange);
// 			if(Range <= MaxRange && Math::Abs(Range - MaxRange) < ClosestDiff)
// 			{
// 				ClosestDiff = Math::Abs(Range - MaxRange);
// 				FoundIndex = i;
// 			}
// 		}

// 		if(FoundIndex < 0)
// 			return false;
		
// 		Out = EpiCenterRangeData[FoundIndex];
// 		Out.InternalBonusScore = 10000 * (EpiCenterRangeData.Num() - FoundIndex);
// 		return true;
// 	}
// };