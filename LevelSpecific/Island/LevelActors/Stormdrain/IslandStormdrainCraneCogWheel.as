event void FIslandStormdrainCraneCogWheel(float Progress);

class AIslandStormdrainCraneCogWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent CogWheelMovingRoot;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent ShieldRootLocation;

	UPROPERTY(DefaultComponent, Attach = "ShieldRootLocation")
	USceneComponent ShieldMovingRoot;

	UPROPERTY(DefaultComponent, Attach = "CogWheelMovingRoot")
	UStaticMeshComponent CogWheel;
	default CogWheel.RelativeScale3D = FVector(2, 2, 2);

	UPROPERTY(DefaultComponent, Attach = "ShieldMovingRoot")
	UStaticMeshComponent Shield;

	UPROPERTY(DefaultComponent, Attach = "CogWheelMovingRoot")
	UStaticMeshComponent Target;
	//default Target.RelativeScale3D = FVector(2, 2, 2);

	UPROPERTY(DefaultComponent, Attach = "Target")
	UIslandRedBlueImpactShieldResponseComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = "ImpactComp")
	UIslandRedBlueTargetableComponent TargetComp;

	UPROPERTY()
	FIslandStormdrainCraneCogWheel ProgressUpdate;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings MioSettings;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings ZoeSettings;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UMaterialInterface DeactivatedMaterial;

	UPROPERTY()
	UMaterialInterface FeedbackMaterial;

	UPROPERTY()
	UMaterialInterface WrongFeedbackMaterial;

	UPROPERTY(EditInstanceOnly)
	AIslandStormdrainCraneCogWheel OtherCogWheel;

	UPROPERTY()
	FHazeTimeLike CogWheelAnimation;	
	default CogWheelAnimation.Duration = 1.0;
	default CogWheelAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default CogWheelAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FHazeTimeLike ResetAnimation;
	default ResetAnimation.Duration = 1.0;
	default ResetAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ResetAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FHazeTimeLike ShieldAnimation;
	default ShieldAnimation.Duration = 0.5;
	default ShieldAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ShieldAnimation.Curve.AddDefaultKey(0.5, 1.0);

	float CurrentRotation = 0;
	float TargetRotation = 0;
	UPROPERTY(EditInstanceOnly)
	float RotationPerStep = 120;

	bool bReachedEnd = false;

	UPROPERTY()
	float MaxShieldRotation = 90;

	int ShootWrongCounter = 0;
	int MaxShootWrongCounter = 3;

	float ActivateTargetCountdown = 0;
	float MaxActivateTargetCountdown = 0.5;
	bool bHasBeenActivated;

	UPROPERTY(EditInstanceOnly)
	bool bActive;

	UPROPERTY(EditInstanceOnly)
	TArray<EHazePlayer> ShootSequence;

	EHazePlayer CurrentCorrectTarget;

	//int SequenceCount = 0;
	float SequenceCountFloat = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(ShootSequence.Num() > 0)
		{
			if(ShootSequence[0] == EHazePlayer::Mio)
			{
				Target.SetMaterial(0, MioMaterial);
			}
			else
			{
				Target.SetMaterial(0, ZoeMaterial);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CogWheelAnimation.BindUpdate(this, n"TL_CogWheelRotationUpdate");
		CogWheelAnimation.BindFinished(this, n"TL_CogWheelRotationFinished");
		ResetAnimation.BindUpdate(this, n"TL_ResetAnimationUpdate");
		ResetAnimation.BindFinished(this, n"TL_ResetAnimationFinished");
		ShieldAnimation.BindUpdate(this, n"TL_ShieldAnimationUpdate");
		ShieldAnimation.BindFinished(this, n"TL_ShieldAnimationFinished");

		ImpactComp.OnImpactOnShield.AddUFunction(this, n"HandleImpact");
		ImpactComp.OnImpactWhenShieldDestroyed.AddUFunction(this, n"HandleFullAlpha");
		
		SetActive(bActive);

	}

	UFUNCTION()
	void SetActive(bool bNewActive)
	{
		bActive = bNewActive;
		if(bActive)
		{
			ShieldAnimation.Reverse();
		}

		else
		{
			ActivateShield();
		}
	}

	UFUNCTION()
	void TL_CogWheelRotationUpdate(float CurveValue)
	{
		if(SequenceCountFloat + CurveValue < ShootSequence.Num())
		{
			CurrentRotation = (SequenceCountFloat * RotationPerStep) + RotationPerStep*CurveValue;
			CogWheelMovingRoot.SetRelativeRotation(FRotator(CurrentRotation, 0, 0));
			ProgressUpdate.Broadcast((SequenceCountFloat + CurveValue)/ShootSequence.Num());
		}
	}

	UFUNCTION()
	void TL_CogWheelRotationFinished()
	{
		SequenceCountFloat+=1;
		SequenceCountFloat = Math::Min(SequenceCountFloat, ShootSequence.Num());

		if(SequenceCountFloat == ShootSequence.Num())
		{
			bReachedEnd = true;
			SetActorTickEnabled(false);
		}

		else
		{
			ActivateTargetCountdown = MaxActivateTargetCountdown;
		}
	}

	UFUNCTION()
	void TL_ResetAnimationUpdate(float CurveValue)
	{
		CurrentRotation = SequenceCountFloat*RotationPerStep -  RotationPerStep*CurveValue*SequenceCountFloat;
		CogWheelMovingRoot.SetRelativeRotation(FRotator(CurrentRotation, 0, 0));
		ProgressUpdate.Broadcast((SequenceCountFloat * (1-CurveValue))/ShootSequence.Num());
	}

	UFUNCTION()
	void TL_ResetAnimationFinished()
	{
		SequenceCountFloat = 0;
		ShieldAnimation.ReverseFromEnd();
	}

	UFUNCTION()
	void TL_ShieldAnimationUpdate(float CurveValue)
	{
		ShieldMovingRoot.SetRelativeLocation(FVector(0,0,-200*CurveValue));
	}

	UFUNCTION()
	void TL_ShieldAnimationFinished()
	{
		if(ShieldAnimation.GetValue() == 1)
		{
			if(bActive)
			{
				if(SequenceCountFloat == 0)
				{
					ShieldAnimation.ReverseFromEnd();
				}

				else
				{
					ResetAnimation.SetPlayRate(1.0/(SequenceCountFloat));
					ResetAnimation.PlayFromStart();
				}
			}
		}

		else
		{
			ActivateTargetCountdown = MaxActivateTargetCountdown;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ActivateTargetCountdown > 0)
		{
			ActivateTargetCountdown -= DeltaSeconds;
			if(ActivateTargetCountdown <= 0)
			{
				ActivateTarget();
			}
		}

		if(SequenceCountFloat > 0 && !bReachedEnd)
		{
			if(!CogWheelAnimation.IsPlaying())
			{
				SequenceCountFloat -= DeltaSeconds * 0.06;
				CurrentRotation = SequenceCountFloat*RotationPerStep;
				CogWheelMovingRoot.SetRelativeRotation(FRotator(CurrentRotation, 0, 0));
				ProgressUpdate.Broadcast(SequenceCountFloat/ShootSequence.Num());
			}
		}
	}

	void ActivateTarget()
	{
		if(SequenceCountFloat < ShootSequence.Num() && !bReachedEnd)
		{
			ImpactComp.UnblockImpactForPlayer(Game::GetZoe(), this);
			ImpactComp.UnblockImpactForPlayer(Game::GetMio(), this);
			ImpactComp.ResetShieldAlpha();
			ShootWrongCounter = 0;

			if(ShootSequence[Math::FloorToInt(SequenceCountFloat)] == EHazePlayer::Mio)
			{
				Target.SetMaterial(0, MioMaterial);
				ImpactComp.Settings = MioSettings;
				TargetComp.DisableForPlayer(Game::GetZoe(), this);
				TargetComp.EnableForPlayer(Game::GetMio(), this);
				CurrentCorrectTarget = EHazePlayer::Mio;
			}
			else
			{
				Target.SetMaterial(0, ZoeMaterial);
				ImpactComp.Settings = ZoeSettings;
				TargetComp.DisableForPlayer(Game::GetMio(), this);
				TargetComp.EnableForPlayer(Game::GetZoe(), this);
				CurrentCorrectTarget = EHazePlayer::Zoe;
			}
		}
	}

	UFUNCTION()
	void HandleImpact(FIslandRedBlueImpactShieldResponseParams Data)
	{

		if(Data.Player != Game::GetPlayer(CurrentCorrectTarget))
		{
			ShootWrongCounter++;
			if(ShootWrongCounter >= MaxShootWrongCounter)
			{
				ShootWrongCounter = 0;
				ActivateShield();
				OtherCogWheel.ActivateShield();
			}
		}
	}

	UFUNCTION()
	void HandleFullAlpha(FIslandRedBlueImpactShieldResponseParams Data)
	{
		
		if(Data.Player == Game::GetPlayer(CurrentCorrectTarget))
		{
			Target.SetMaterial(0, DeactivatedMaterial);
			bHasBeenActivated = true;
			TargetComp.DisableForPlayer(Game::GetZoe(), this);
			TargetComp.DisableForPlayer(Game::GetMio(), this);
			if(OtherCogWheel.bHasBeenActivated)
			{
				MoveToNextStep();
				OtherCogWheel.MoveToNextStep();
			}	
		}
	}

	void ActivateShield()
	{
		TargetComp.DisableForPlayer(Game::GetZoe(), this);
		TargetComp.DisableForPlayer(Game::GetMio(), this);
		bHasBeenActivated = false;
		ImpactComp.BlockImpactForPlayer(Game::GetMio(), this);
		ImpactComp.BlockImpactForPlayer(Game::GetZoe(), this);
		Target.SetMaterial(0, DeactivatedMaterial);
		ShieldAnimation.PlayFromStart();
	}

	void MoveToNextStep()
	{
		bHasBeenActivated = false;
		ImpactComp.BlockImpactForPlayer(Game::GetMio(), this);
		ImpactComp.BlockImpactForPlayer(Game::GetZoe(), this);
		CogWheelAnimation.PlayFromStart();
	}
}