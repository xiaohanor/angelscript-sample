UCLASS(HideCategories = "ComponentTick Rendering Disable Debug Activation Cooking Tags LOD AssetUserData Navigation Variable")
class UCameraShakeForceFeedbackComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "CameraShake")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere, Category = "CameraShake")
	float CameraShakeScale = 1.0;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditAnywhere, Category = "ForceFeedback")
	float ForceFeedbackScale = 1.0;

	UPROPERTY(EditAnywhere)
	bool bPlayInWorld = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bPlayInWorld", EditConditionHides))
	float InnerRadius = 1000.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bPlayInWorld", EditConditionHides))
	float OuterRadius = 2000.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bPlayInWorld", EditConditionHides))
	EHazeWorldCameraShakeSamplePosition SamplePosition;

	UPROPERTY(EditAnywhere)
	bool bVisualize = true;

	//No specified player = play on both
	UFUNCTION()
	void ActivateCameraShakeAndForceFeedback(AHazePlayerCharacter TargetPlayer = nullptr)
	{
		TArray<AHazePlayerCharacter> TargetPlayers;
		if (TargetPlayer == nullptr)
		{
			TargetPlayers.Add(Game::Mio);
			TargetPlayers.Add(Game::Zoe);
		}
		else
		{
			TargetPlayers.Add(TargetPlayer);
		}

		if (bPlayInWorld)
		{
			if (CameraShake.IsValid())
			{
				for (AHazePlayerCharacter Player : TargetPlayers)
					Player.PlayWorldCameraShake(CameraShake, this, WorldLocation, InnerRadius, OuterRadius, 1.0, CameraShakeScale, SamplePosition = SamplePosition);
			}

			if (ForceFeedback != nullptr)
			{
				EHazeSelectPlayer TargetFFPlayer = EHazeSelectPlayer::Both;
				if (TargetPlayer != nullptr)
				{
					if (TargetPlayer.IsMio())
						TargetFFPlayer = EHazeSelectPlayer::Mio;
					else if (TargetPlayer.IsZoe())
						TargetFFPlayer = EHazeSelectPlayer::Zoe;
				}
					
				if(TargetFFPlayer != EHazeSelectPlayer::None)
					ForceFeedback::PlayWorldForceFeedback(ForceFeedback, WorldLocation, true, this, InnerRadius, OuterRadius - InnerRadius, 1.0, ForceFeedbackScale, TargetFFPlayer);
			}
		}
		else
		{
			for (AHazePlayerCharacter Player : TargetPlayers)
			{
				if (CameraShake.IsValid())
					Player.PlayCameraShake(CameraShake, this, CameraShakeScale);
				
				if (ForceFeedback != nullptr)
					Player.PlayForceFeedback(ForceFeedback, false, true, this, ForceFeedbackScale);
			}
		}
	}
}

#if EDITOR
class UCameraShakeForceFeedbackScriptVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCameraShakeForceFeedbackComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UCameraShakeForceFeedbackComponent Comp = Cast<UCameraShakeForceFeedbackComponent>(Component);
        if (Comp == nullptr)
            return;

		if (Comp.bVisualize)
		{
			DrawWireSphere(Comp.WorldLocation, Comp.InnerRadius, FLinearColor::Green, 2.0);
			DrawWireSphere(Comp.WorldLocation, Comp.OuterRadius, FLinearColor::Red, 2.0);
		}
    }
}
#endif