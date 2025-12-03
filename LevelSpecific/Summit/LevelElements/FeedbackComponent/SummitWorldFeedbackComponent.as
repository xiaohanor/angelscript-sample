//When a generic system is made, split this into two components - one shot and looping
class USummitWorldFeedbackComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> CameraShake;
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> LoopingCameraShake;
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float InnerRadius = 100.0;
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float OuterRadius = 500.0;
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float CameraShakeIntensity = 1.0;
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float LoopingCameraShakeIntensity = 1.0;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect OneShotFF;
	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	float FFMaxDistance = 500.0;
	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0.0, 0.0);
	default Curve.AddDefaultKey(1.0, 1.0);
	
	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	float LoopingFFFrequency = 15.0;
	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	float LoopingFFIntensity = 1.0;

	TPerPlayer<bool> bPlayLooping;

	float TargetCameraShakeTime = 0.3;
	float CurrentCameraShakeTime;

	UFUNCTION()
	void PlayOneShotFeedbackForBoth()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			PlayOneShotFeedback(Player);
	}

	UFUNCTION()
	void PlayOneShotFeedback(AHazePlayerCharacter Player)
	{
		float FFDistance = (Player.ActorLocation - WorldLocation).Size();
		float FFMultiplier = 1.0 - Math::Saturate(FFDistance / FFMaxDistance);
		Player.PlayForceFeedback(OneShotFF, false, false, this, Curve.GetFloatValue(FFMultiplier));

		Player.PlayWorldCameraShake(CameraShake, this, WorldLocation, InnerRadius, OuterRadius, Scale = CameraShakeIntensity);
	}

	UFUNCTION()
	void StartLoopingFeedbackForBoth()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			StartLoopingFeedback(Player);
	}

	UFUNCTION()
	void StopLoopingFeedbackForBoth()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			StopLoopingFeedback(Player);
	}

	UFUNCTION()
	void StartLoopingFeedback(AHazePlayerCharacter Player)
	{
		bPlayLooping[Player] = true;
	}

	UFUNCTION()
	void StopLoopingFeedback(AHazePlayerCharacter Player)
	{
		bPlayLooping[Player] = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (bPlayLooping[Player])
			{
				float FFDistance = (Player.ActorLocation - WorldLocation).Size();
				float FFMultiplier = 1.0 - Math::Saturate(FFDistance / FFMaxDistance);
				float FFCurveMultplier = Curve.GetFloatValue(FFMultiplier);
				
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = 0.5 + Math::Sin(Time::GameTimeSeconds * LoopingFFFrequency);
				FF.RightMotor = 0.5 + Math::Sin(Time::GameTimeSeconds * -LoopingFFFrequency);
				Player.SetFrameForceFeedback(FF, FFCurveMultplier * LoopingFFIntensity);

				CurrentCameraShakeTime += DeltaSeconds;

				if (CurrentCameraShakeTime > TargetCameraShakeTime)
				{
					Player.PlayWorldCameraShake(LoopingCameraShake, this, WorldLocation, InnerRadius, OuterRadius, Scale = LoopingCameraShakeIntensity);
					CurrentCameraShakeTime = 0.0;
				}
			}
		}
	}
};