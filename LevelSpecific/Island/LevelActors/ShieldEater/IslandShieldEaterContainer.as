event void FAIslandShieldEaterContainer();

class AIslandShieldEaterContainer: AHazeActor
{
	
	UPROPERTY()
	FAIslandGunRangeTargetSignature OnImpact;
	UPROPERTY()
	FAIslandGunRangeTargetSignature OnActivated;
	UPROPERTY()
	FAIslandGunRangeTargetSignature OnDead;
	UPROPERTY()
	FAIslandGunRangeTargetSignature OnReachedDestination;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetALock;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetALockDestination;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetBLock;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetBLockDestination;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetAComp;

	UPROPERTY(DefaultComponent, Attach = TargetAComp)
	UStaticMeshComponent TargetAMesh;

	UPROPERTY(DefaultComponent, Attach = TargetAComp)
	USceneComponent PanelOneAttachPoint;

	UPROPERTY(DefaultComponent, Attach = TargetAMesh)
	UIslandRedBlueImpactCounterResponseComponent TargetAComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetADestination;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetBDestination;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TargetBComp;

	UPROPERTY(DefaultComponent, Attach = TargetBComp)
	UStaticMeshComponent TargetBMesh;

	UPROPERTY(DefaultComponent, Attach = TargetBComp)
	USceneComponent PanelTwoAttachPoint;

	UPROPERTY(DefaultComponent, Attach = TargetBMesh)
	UIslandRedBlueImpactCounterResponseComponent TargetBComponent;

	UPROPERTY(DefaultComponent, Attach = TargetAComp)
	UIslandRedBlueTargetableComponent AutoTargetAComp;

	UPROPERTY(DefaultComponent, Attach = TargetBComp)
	UIslandRedBlueTargetableComponent AutoTargetBComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCameraShakeForceFeedbackComponent OpenCamShakeFFComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditAnywhere)
	EIslandRedBlueWeaponType BlockColor;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel PanelOneRef;

	UPROPERTY(EditInstanceOnly)
	AIslandOverloadShootablePanel PanelTwoRef;

	UPROPERTY()
	UForceFeedbackEffect CompletedFeedback;

	bool bIsActive;

	UPROPERTY()
	FHazeTimeLike  TargetAAnimation;
	default TargetAAnimation.Duration = 0.35;
	default TargetAAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FHazeTimeLike  TargetBAnimation;
	default TargetBAnimation.Duration = 0.35;
	default TargetBAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransformB;
	FQuat StartingRotationB;
	FVector StartingPositionB;
	FTransform EndingTransformB;
	FQuat EndingRotationB;
	FVector EndingPositionB;

	UPROPERTY()
	FHazeTimeLike  OpenAnimation;
	default OpenAnimation.Duration = 0.24;
	default OpenAnimation.UseLinearCurveZeroToOne();

	FTransform OpenStartingTransform;
	FQuat OpenStartingRotation;
	FVector OpenStartingPosition;
	FTransform OpenEndingTransform;
	FQuat OpenEndingRotation;
	FVector OpenEndingPosition;

	UPROPERTY()
	FHazeTimeLike  DelayAnimation;
	default DelayAnimation.Duration = 10;
	default DelayAnimation.UseLinearCurveZeroToOne();

	float CurrentAlpha;
	AHazePlayerCharacter LastPlayerImpacter;

	bool bTargetAShot;
	bool bTargetBShot;
	float Damage = 0.085;
	float TargetAHealth = 0;
	float TargetBHealth = 0;

	UPROPERTY()
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY()
	FHazeTimeLike  LockAAnimation;
	default LockAAnimation.Duration = 0.2;
	default LockAAnimation.UseLinearCurveZeroToOne();

	UPROPERTY()
	FHazeTimeLike  LockBAnimation;
	default LockBAnimation.Duration = 0.2;
	default LockBAnimation.UseLinearCurveZeroToOne();

	FTransform LockATransform;
	FQuat LockARotation;
	FTransform LockBTransform;
	FQuat LockBRotation;
	FTransform LockATransformDestination;
	FQuat LockARotationDestination;
	FTransform LockBTransformDestination;
	FQuat LockBRotationDestination;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (BlockColor == EIslandRedBlueWeaponType::Red)
			UsableByPlayer = EHazePlayer::Zoe;
		else
			UsableByPlayer = EHazePlayer::Mio;
			
		TargetAComponent.OnImpactEvent.AddUFunction(this, n"ImpactTargetA");
		TargetBComponent.OnImpactEvent.AddUFunction(this, n"ImpactTargetB");
		TargetBComponent.BlockImpactForColor(BlockColor, this);
		TargetAComponent.BlockImpactForColor(BlockColor, this);

		LastPlayerImpacter = Game::GetPlayer(UsableByPlayer);

		if (PanelOneRef != nullptr)
		{
			PanelOneRef.OnOvercharged.AddUFunction(this, n"HandlePanelOneOvercharge");
			AutoTargetAComp.DisableForPlayer(Game::GetPlayer(UsableByPlayer), this);
		}
		if (PanelTwoRef != nullptr)
		{
			PanelTwoRef.OnOvercharged.AddUFunction(this, n"HandlePanelTwoOvercharge");
			AutoTargetBComp.DisableForPlayer(Game::GetPlayer(UsableByPlayer), this);
		}


		StartingTransform = TargetAComp.GetRelativeTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();
		EndingTransform = TargetADestination.GetRelativeTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		StartingTransformB = TargetBComp.GetRelativeTransform();
		StartingPositionB = StartingTransformB.GetLocation();
		StartingRotationB = StartingTransformB.GetRotation();
		EndingTransformB = TargetBDestination.GetRelativeTransform();
		EndingPositionB = EndingTransformB.GetLocation();
		EndingRotationB = EndingTransformB.GetRotation();

		OpenStartingTransform = MovableComp.GetRelativeTransform();
		OpenStartingPosition = OpenStartingTransform.GetLocation();
		OpenStartingRotation = OpenStartingTransform.GetRotation();
		OpenEndingTransform = DestinationComp.GetRelativeTransform();
		OpenEndingPosition = OpenEndingTransform.GetLocation();
		OpenEndingRotation = OpenEndingTransform.GetRotation();

		LockATransform = TargetALock.GetRelativeTransform();
		LockARotation = LockATransform.GetRotation();
		LockATransformDestination = TargetALockDestination.GetRelativeTransform();
		LockARotationDestination = LockATransformDestination.GetRotation();

		LockBTransform = TargetBLock.GetRelativeTransform();
		LockBRotation = LockBTransform.GetRotation();
		LockBTransformDestination = TargetBLockDestination.GetRelativeTransform();
		LockBRotationDestination = LockBTransformDestination.GetRotation();

		TargetAAnimation.BindUpdate(this, n"OnUpdateA");
		TargetAAnimation.BindFinished(this, n"OnFinishedA");
		TargetBAnimation.BindUpdate(this, n"OnUpdateB");
		TargetBAnimation.BindFinished(this, n"OnFinishedB");

		OpenAnimation.BindUpdate(this, n"OnOpenUpdate");
		OpenAnimation.BindFinished(this, n"OnOpenFinished");

		LockAAnimation.BindUpdate(this, n"OnLockAUpdate");
		LockAAnimation.BindFinished(this, n"OnLockAFinished");

		LockBAnimation.BindUpdate(this, n"OnLockBUpdate");
		LockBAnimation.BindFinished(this, n"OnLockBFinished");

		if(HasControl())
			DelayAnimation.BindFinished(this, n"CrumbOnDelayFinished");

		AutoTargetAComp.DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);
		AutoTargetBComp.DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);
		


		// OnUpdate(1);

		bIsActive = false;

	}

	UFUNCTION()
	void ImpactTargetA(FIslandRedBlueImpactResponseParams Data)
	{
		if (PanelOneRef != nullptr)
			return;
		if (bTargetAShot)
			return;

		if (TargetAHealth == 1)
			return;

		LastPlayerImpacter = Data.Player;

		TargetAHealth = TargetAHealth + Damage;

		if (TargetAHealth > 1)
			TargetAHealth = 1;

		OnUpdateA(TargetAHealth);

		if (TargetAHealth == 1)
		{
			TargetAActivated();
		}
		
	}

	UFUNCTION()
	void ImpactTargetB(FIslandRedBlueImpactResponseParams Data)
	{
		if (PanelOneRef != nullptr)
			return;
		if (bTargetBShot)
			return;

		if (TargetBHealth == 1)
			return;
		
		LastPlayerImpacter = Data.Player;

		TargetBHealth = TargetBHealth + Damage;

		if (TargetBHealth > 1)
			TargetBHealth = 1;

		OnUpdateB(TargetBHealth);

		if (TargetBHealth == 1)
		{
			TargetBActivated();
		}

	}

	UFUNCTION()
	void HandlePanelOneOvercharge()
	{
		if (bTargetAShot)
			return;

		if(!HasControl())
			return;
		
		CrumbOverchargePanelOne();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOverchargePanelOne()
	{
		TargetBHealth = 1;
		TargetAAnimation.PlayFromStart();
		PanelOneRef.DisablePanel();
		PanelOneRef.OverchargeComp.ResetChargeAlpha(this);

		FIslandShieldEaterContainerCylinderMoveEffectParams EffectParams;
		EffectParams.Cylinder = TargetAMesh;
		UIslandShieldEaterContainerEffectHandler::Trigger_OnCylinderMoveIn(this, EffectParams);
	}

	UFUNCTION()
	void HandlePanelTwoOvercharge()
	{
		if (bTargetBShot)
			return;

		if(!HasControl())
			return;

		CrumbOverchargePanelTwo();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOverchargePanelTwo()
	{
		TargetBHealth = 1;
		TargetBAnimation.PlayFromStart();
		PanelTwoRef.DisablePanel();
		PanelTwoRef.OverchargeComp.ResetChargeAlpha(this);

		FIslandShieldEaterContainerCylinderMoveEffectParams EffectParams;
		EffectParams.Cylinder = TargetBMesh;
		UIslandShieldEaterContainerEffectHandler::Trigger_OnCylinderMoveIn(this, EffectParams);
	}

	UFUNCTION()
	void DestroyTarget()
	{
		bIsActive = false;
	}

	UFUNCTION()
	void OnUpdateA(float Alpha)
	{
		TargetAComp.SetRelativeLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinishedA()
	{
		if (TargetAAnimation.IsReversed())
		{
			bTargetAShot = false;
			TargetAHealth = 0;
			BP_OnDeactivated();

			UIslandShieldEaterContainerEffectHandler::Trigger_OnForceFieldRegenerated(this);

			if (PanelOneRef != nullptr)
			{
				PanelOneRef.EnablePanel();
			}
			return;
		}

		if (PanelOneRef != nullptr)
		{
			TargetAActivated();
			LockAAnimation.Play();
		}
	}

	UFUNCTION()
	void OnUpdateB(float Alpha)
	{
		TargetBComp.SetRelativeLocationAndRotation(Math::Lerp(StartingPositionB, EndingPositionB, Alpha), FQuat::SlerpFullPath(StartingRotationB, EndingRotationB, Alpha));
	}

	UFUNCTION()
	void OnFinishedB()
	{
		if (TargetBAnimation.IsReversed())
		{
			bTargetBShot = false;
			TargetBHealth = 0;
			BP_OnDeactivated();
			if (PanelTwoRef != nullptr)
			{
				PanelTwoRef.EnablePanel();
			}
			return;
		}
		if (PanelOneRef != nullptr)
		{
			TargetBActivated();
			LockBAnimation.Play();
		}
	}

	UFUNCTION()
	void OnOpenUpdate(float Alpha)
	{
		MovableComp.SetRelativeLocationAndRotation(Math::Lerp(OpenStartingPosition, OpenEndingPosition, Alpha), FQuat::SlerpFullPath(OpenStartingRotation, OpenEndingRotation, Alpha));
	}

	UFUNCTION()
	void OnOpenFinished()
	{
		if (OpenAnimation.IsReversed())
		{
			if(HasControl())
				CrumbResetCylinders();
		}
		else
		{
			DelayAnimation.PlayFromStart();
		}

		OpenCamShakeFFComp.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbResetCylinders()
	{
		TargetAAnimation.ReverseFromEnd();
		TargetBAnimation.ReverseFromEnd();

		FIslandShieldEaterContainerCylinderMoveEffectParams EffectParams;
		EffectParams.Cylinder = TargetAMesh;
		UIslandShieldEaterContainerEffectHandler::Trigger_OnCylinderMoveOut(this, EffectParams);
		EffectParams.Cylinder = TargetBMesh;
		UIslandShieldEaterContainerEffectHandler::Trigger_OnCylinderMoveOut(this, EffectParams);
	}

	UFUNCTION()
	void OnLockAUpdate(float Alpha)
	{
		TargetALock.SetRelativeRotation(FQuat::SlerpFullPath(LockARotation, LockARotationDestination, Alpha));
	}

	UFUNCTION()
	void OnLockAFinished()
	{
		
	}

	UFUNCTION()
	void OnLockBUpdate(float Alpha)
	{
		TargetBLock.SetRelativeRotation(FQuat::SlerpFullPath(LockBRotation, LockBRotationDestination, Alpha));
	}

	UFUNCTION()
	void OnLockBFinished()
	{
		
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnDelayFinished()
	{
		OpenAnimation.ReverseFromEnd();
		LockAAnimation.Reverse();
		LockBAnimation.Reverse();
		PanelOneRef.OverchargeComp.ResetChargeAlpha();
		PanelTwoRef.OverchargeComp.ResetChargeAlpha();
	}

	UFUNCTION()
	void TargetAActivated()
	{
		bTargetAShot = true;
		if(LastPlayerImpacter != nullptr)
			LastPlayerImpacter.PlayForceFeedback(CompletedFeedback, false, false, this);
		BP_OnTagetAActivated();
		CheckTargets();
	}
	
	UFUNCTION()
	void TargetBActivated()
	{
		bTargetBShot = true;
		if(LastPlayerImpacter != nullptr)
			LastPlayerImpacter.PlayForceFeedback(CompletedFeedback, false, false, this);
		BP_OnTagetBActivated();
		CheckTargets();
	}

	UFUNCTION()
	void CheckTargets()
	{
		if (bTargetAShot == true && bTargetBShot == true)
		{
			if(HasControl())
				CrumbDestroyForceField();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDestroyForceField()
	{
		OpenAnimation.PlayFromStart();
		BP_OnCompleted();

		UIslandShieldEaterContainerEffectHandler::Trigger_OnForceFieldDestroyed(this);
	}

	UFUNCTION()
	void ResetContainer()
	{
		DelayAnimation.Stop();
		OpenAnimation.ReverseFromEnd();
		LockAAnimation.Reverse();
		LockBAnimation.Reverse();
		PanelOneRef.OverchargeComp.ResetChargeAlpha();
		PanelTwoRef.OverchargeComp.ResetChargeAlpha();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnTagetAActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnTagetBActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnCompleted() {}

}