struct FMovableCamShakeSettings
{
	UPROPERTY()
	float ShakeRadius = 500;
	
	UPROPERTY()
	FVector EpicenterOffset = FVector::ZeroVector;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(meta = (ClampMin = "1.0"))
	float EaseOutExp = 2;

	UPROPERTY(Meta = (EditCondition = "!bUseCurveAsset", EditConditionHides))
	float Scale = 1.0;

	UPROPERTY()
	bool bUseCurveAsset = false;

	UPROPERTY(Meta = (EditCondition = "bUseCurveAsset"))
	UCurveFloat ShakeCurve;

	UPROPERTY()
	bool bActiveForMio = true;

	UPROPERTY()
	bool bActiveForZoe = true;
}

class UMovableCameraShakeComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FMovableCamShakeSettings MovableCamShakeSettings;

	UPROPERTY(EditAnywhere)
	bool bDisableEditorVisualizer = false;

	TPerPlayer<bool> bCameraShakeActiveForPlayer;
	TPerPlayer<UCameraShakeBase> CamShakeInstance;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UFUNCTION()
	void ActivateMovableCameraShake()
	{
		SetComponentTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateMovableCameraShake()
	{
		SetComponentTickEnabled(false);
		StopAllMovingCameraShakes();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		StopAllMovingCameraShakes();	
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		StopAllMovingCameraShakes();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{
			if(Player == Game::Mio && !MovableCamShakeSettings.bActiveForMio)
				continue;

			if(Player == Game::Zoe && !MovableCamShakeSettings.bActiveForZoe)
				continue;

			float ShakeScale = GetShakeScale(Player.ActorLocation);
			if(ShakeScale > 0)
			{
				if(!bCameraShakeActiveForPlayer[Player])
				{
					CamShakeInstance[Player] = Player.PlayCameraShake(MovableCamShakeSettings.CameraShake, this, ShakeScale);
					bCameraShakeActiveForPlayer[Player] = true;
				}
				else
				{
					CamShakeInstance[Player].ShakeScale = ShakeScale;
				}
			}
			else
			{
				if(bCameraShakeActiveForPlayer[Player])
				{
					bCameraShakeActiveForPlayer[Player] = false;
					Player.StopCameraShakeInstance(CamShakeInstance[Player], true);
				}
			}
		}

#if EDITOR
		if(bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(Owner.ActorLocation + MovableCamShakeSettings.EpicenterOffset, MovableCamShakeSettings.ShakeRadius, 12, FLinearColor::Purple);
#endif
	
	}

	void StopAllMovingCameraShakes()
	{
		for(auto Player : Game::Players)
		{
			Player.StopCameraShakeByInstigator(this, true);
			bCameraShakeActiveForPlayer[Player] = false;
		}
	}

	float GetShakeScale(FVector PlayerLocation)
	{
		float NormalizedDist = (PlayerLocation - Owner.ActorLocation + MovableCamShakeSettings.EpicenterOffset).Size() / MovableCamShakeSettings.ShakeRadius;
		float Alpha = Math::Clamp(1.0 - NormalizedDist, 0.0, 1.0);
		
		if(MovableCamShakeSettings.bUseCurveAsset)
		{
			//Just in case the curve asset doesn't have a value that goes to 0.
			if(Alpha <= 0)
				return 0;
			else
				return MovableCamShakeSettings.ShakeCurve.GetFloatValue(Alpha);
		}
		else
		{
			return Math::EaseOut(0.0, MovableCamShakeSettings.Scale, Alpha, MovableCamShakeSettings.EaseOutExp);
		}
	}	
};

class UMovableCameraShakeVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMovableCameraShakeComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ShakeComp = Cast<UMovableCameraShakeComponent>(Component);
		if(ShakeComp.bDisableEditorVisualizer)
			return;

		DrawWireSphere(ShakeComp.Owner.ActorLocation + ShakeComp.MovableCamShakeSettings.EpicenterOffset, ShakeComp.MovableCamShakeSettings.ShakeRadius, FLinearColor::Purple, 3);
	}
}