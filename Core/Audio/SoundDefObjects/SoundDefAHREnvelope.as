// class USoundDefAHREnvelope : USoundDefAHREnvelopeObject
// {
// 	float PrevRawCurveValue = 0.0;

// 	UFUNCTION(BlueprintOverride)
// 	void BP_Start(bool bStartFromZero, bool bIsLooping)
// 	{
// 		if(bStartFromZero || EvaluationStage == EEnvelopeEvaluationStage::Inactive)
// 		{
// 			LastTimeIndex = 0.0;	
// 			LastEnvelopeAlphaValue = 0.0;	
// 			EvaluationStage = EEnvelopeEvaluationStage::Attack;

// 		}
		
// 		if(EvaluationStage == EEnvelopeEvaluationStage::Hold)
// 		{
// 			LastTimeIndex = 0.0;
// 		}
// 		else if(EvaluationStage == EEnvelopeEvaluationStage::Release)
// 		{
// 			LastTimeIndex = GetStageTimePosFromAlpha();
// 			EvaluationStage = EEnvelopeEvaluationStage::Attack;
// 		}
		
// 		bLooping = bIsLooping;	
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void BP_Stop()
// 	{
// 		if(EvaluationStage == EEnvelopeEvaluationStage::Hold)
// 			LastTimeIndex = 0.0;
		
// 		else if(EvaluationStage == EEnvelopeEvaluationStage::Attack)
// 		{
// 			LastTimeIndex = GetStageTimePosFromAlpha();
// 		}
		
// 		EvaluationStage = EEnvelopeEvaluationStage::Release;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void Evaluate(float DeltaSeconds, const FAHREnvelopeEvaluationData& InEvaluationData)
// 	{
// 		if(EvaluationStage == EEnvelopeEvaluationStage::Inactive)
// 		{
// 			EnvelopeAlphaValue = 0.0;
// 			return;
// 		}

// 		EvaluationData = InEvaluationData;
		
// 		const float MaxLength = GetCurrentStageLength();
// 		const float TimeIndex = Math::Min(LastTimeIndex += DeltaSeconds, MaxLength);
// 		EnvelopeAlphaValue = GetAlphaIndex(TimeIndex);

// 		// If looping and in Hold, MaxLength returns -1
// 		if(TimeIndex > 0
// 		&& TimeIndex >= MaxLength)
// 		{
// 			LastTimeIndex = 0.0;
// 			AdvanceToNextStage();
// 		}
		
// 		// If Attack, Hold or Release time is 0 just advance 
// 		if(MaxLength == 0)
// 			AdvanceToNextStage();
	
// 		LastEnvelopeAlphaValue = EnvelopeAlphaValue;

// 		//PrintToScreenScaled("Time: " + TimeIndex);

// 		ExecuteOnTickActive(DeltaSeconds);
// 	}

// 	float GetAlphaIndex(const float InTime)
// 	{
// 		/* TY Anders Olsson <3 */
// 		switch (EvaluationStage)
// 		{
// 			case(EEnvelopeEvaluationStage::Attack):
// 			{	
// 				if(EvaluationData.AttackTime > 0)
// 				{
// 					PrevRawCurveValue = Math::EaseIn(0.0, 1.0, (InTime / EvaluationData.AttackTime), EvaluationData.AttackCurveExp);
// 					return PrevRawCurveValue;
// 				}			
				
// 				return 1.0;
// 			}
// 			case(EEnvelopeEvaluationStage::Hold):
// 			{
// 				return 1.0;
// 			}
// 			case(EEnvelopeEvaluationStage::Release):
// 			{
// 				if(EvaluationData.ReleaseTime > 0)
// 				{
// 					PrevRawCurveValue = Math::EaseOut(1.0, 0.0, (InTime / EvaluationData.ReleaseTime), EvaluationData.ReleaseCurveExp);
// 					return PrevRawCurveValue;
// 				}

// 				return 0.0;
// 			}
// 			default:
// 			{
// 				return 0.0;
// 			}
// 		}

// 		return 0.0;
// 	}

// 	float GetTimeIndex(const float InAlpha, const float InLength, const float InExp)
// 	{
// 		return Math::Lerp(0, InLength, InAlpha);
// 	}

// 	float GetCurrentStageLength()
// 	{
// 		switch (EvaluationStage)
// 		{
// 			case(EEnvelopeEvaluationStage::Attack):
// 			{
// 				return EvaluationData.AttackTime;
// 			}
// 			case(EEnvelopeEvaluationStage::Hold):
// 			{
// 				return bLooping ? -1.0 : EvaluationData.HoldTime;
// 			}
// 			case(EEnvelopeEvaluationStage::Release):
// 			{
// 				return EvaluationData.ReleaseTime;
// 			}
// 			default:
// 			{
// 				return 0.0;
// 			}			
// 		}

// 		return 0.0;
// 	}

// 	void AdvanceToNextStage()
// 	{
// 		switch (EvaluationStage)
// 		{
// 			case(EEnvelopeEvaluationStage::Attack):
// 			{
// 				if(EvaluationData.HoldTime > 0
// 				|| bLooping)
// 				{
// 					EvaluationStage = EEnvelopeEvaluationStage::Hold;

// 					if(bLooping)
// 					{
// 						EnteredLoopingHold();
// 					}				
// 				}
// 				else
// 				{
// 					EvaluationStage = EEnvelopeEvaluationStage::Release;
// 				}
					
// 				break;
// 			}
// 			case(EEnvelopeEvaluationStage::Hold):
// 			{
// 				EvaluationStage = EEnvelopeEvaluationStage::Release;
// 				break;
// 			}
// 			case(EEnvelopeEvaluationStage::Release):
// 			{
// 				EvaluationStage = EEnvelopeEvaluationStage::Inactive;
// 				ExecuteOnReleaseFinished();
// 			}
// 			default:
// 			{
// 				EvaluationStage = EEnvelopeEvaluationStage::Inactive;
// 			}
				
// 		}
// 	}	

// 	float GetStageTimePosFromAlpha()
// 	{
// 		const float SourceTime = LastTimeIndex;

// 		switch (EvaluationStage)
// 		{
// 		case(EEnvelopeEvaluationStage::Attack):
// 			{
// 				float CurveTimeValue = EvaluationData.ReleaseTime * (1.0 - (Math::Pow(PrevRawCurveValue, 1.0 / EvaluationData.ReleaseCurveExp)));
// 				return CurveTimeValue;
// 			}
// 		case(EEnvelopeEvaluationStage::Release):
// 			{
// 				float CurveTimeValue = EvaluationData.AttackTime * Math::Pow(PrevRawCurveValue, 1.0 / EvaluationData.AttackCurveExp);
// 				return CurveTimeValue;
// 			}
// 		default:
// 			{
// 				return -1.0;
// 			}
				
// 		}

// 		return 0.0;
// 	}

// }