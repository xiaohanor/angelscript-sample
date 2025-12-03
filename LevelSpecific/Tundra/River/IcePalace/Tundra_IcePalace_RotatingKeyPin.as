class UTundra_IcePalace_RotatingKeyPinComponent : UActorComponent
{
	ATundra_IcePalace_RotatingKeyPin ActiveKeyPin;
};

struct FRotatingKeyPinActivationParams
{
	ATundra_IcePalace_RotatingKeyPin KeyPin;
};

event void FRotatingKeyPinRotationComplete(bool bCorrectRotation, int StartingIndex);

class ATundra_IcePalace_RotatingKeyPin : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// UPROPERTY(DefaultComponent)
	// UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UTundraShapeshiftingOneShotInteractionComponent  OneShotInteractionComp;

	UPROPERTY(DefaultComponent, Attach = OneShotInteractionComp)
	UHazeSkeletalMeshComponentBase PreviewMesh;
	default PreviewMesh.bIsEditorOnly = true;
	default PreviewMesh.bHiddenInGame = true;
	default PreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default PreviewMesh.bAbsoluteScale = true;
	default PreviewMesh.RelativeScale3D = FVector::OneVector;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Symbol01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Symbol02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Symbol03;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Symbol04;

	UPROPERTY(EditInstanceOnly)
	ATundra_IcePalace_InsideLockLever Lever;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"Tundra_IcePalace_RotatingKeyPinCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.AutoDisableRange = 10000.0;
	default DisableComp.bAutoDisable = true;

	UPROPERTY()
	FHazeTimeLike WigglePinTimelike;
	default WigglePinTimelike.Duration = 1;
	UPROPERTY()
	FHazeTimeLike RaisePinTimelike;
	default RaisePinTimelike.Duration = 1;
	UPROPERTY()
	FHazeTimeLike ShowPinTimelike;
	default ShowPinTimelike.Duration = 1;
	UPROPERTY()
	FHazeTimeLike HidePinTimelike;
	default HidePinTimelike.Duration = 1;
	UPROPERTY()
	FHazeTimeLike LockCompletedTimelike;
	default LockCompletedTimelike.Duration = 1;

	UPROPERTY()
	UCurveFloat RotationCurve;

	UPROPERTY(EditInstanceOnly)
	float ShowPinDelay = 0;

	FRotatingKeyPinRotationComplete OnRotationComplete;

	bool bCurrentlyRotating = false;
	bool bRotatingClockwise = false;
	float RotateTimer = 0;
	float RotateTimerDuration = 0.35;
	float RotationAmount = 90;
	bool bCorrectSymbol = false;
	bool bIsPunchedIn = false;

	FRotator StartingRot;
	FRotator TargetRot;

	FVector HiddenLoc;
	FVector VisibleLoc;
	FVector RaisedLoc;
	FVector CurrentLocBeforeHide;

	FHazeAcceleratedRotator AccRot;
	bool bShouldResetRotation = false;
	float ResetTimer = 0;

	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "3.0"))
	int CurrentSymbolIndex = 0;

	int StartingSymbolIndex = 0;

	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "3.0"))
	int CorrectSymbolIndex = 0;

	//Many players try to match the keypin order to the order of which the symbols are presented on the door. It's not correct, but we want to acknowledge that with VO.
	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "3.0"))
	int AlmostCorrectSymbolIndex = 0;

	bool bAlmostCorrectOrder = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		
		OneShotInteractionComp.OnInteractionStarted.AddUFunction(this, n"OnOneShotStarted");
		
		/* Timelikes */
		WigglePinTimelike.BindUpdate(this, n"WigglePinTimelikeUpdate");
		WigglePinTimelike.SetPlayRate(1 / 0.65);
		RaisePinTimelike.BindUpdate(this, n"RaisePinTimelikeUpdate");
		RaisePinTimelike.PlayRate = 1 / 0.15;
		ShowPinTimelike.BindUpdate(this, n"ShowPinTimelikeUpdate");
		ShowPinTimelike.BindFinished(this, n"ShowPinTimelikeFinished");
		ShowPinTimelike.PlayRate = 1 / 0.5;
		HidePinTimelike.BindUpdate(this, n"HidePinTimelikeUpdate");
		HidePinTimelike.BindFinished(this, n"HidePinTimelikeFinished");
		HidePinTimelike.PlayRate = 1 / 0.5;
		LockCompletedTimelike.BindUpdate(this, n"LockCompletedTimelikeUpdate");
		LockCompletedTimelike.PlayRate = 1;
		/* --- */

		HiddenLoc = MeshRoot.RelativeLocation;
		VisibleLoc = HiddenLoc + FVector(0, 0, -150);
		RaisedLoc = VisibleLoc + FVector(0, 0, 50);

		Lever.OnLeverActivated.AddUFunction(this, n"OnLeverActivated");
		Lever.OnLeverReset.AddUFunction(this, n"OnLeverReset");

		StartingSymbolIndex = CurrentSymbolIndex;
		OneShotInteractionComp.Disable(this);

		//Many players try to match the keypin order to the order of which the symbols are presented on the door. It's not correct, but we want to acknowledge that with VO.
		if(StartingSymbolIndex == AlmostCorrectSymbolIndex)
		{
			bAlmostCorrectOrder = true;
		}
		else
		{
			bAlmostCorrectOrder = false;
		}
	}

	UFUNCTION()
	private void ShowPinTimelikeFinished()
	{
		OneShotInteractionComp.Enable(this);
		
	}

	UFUNCTION()
	private void HidePinTimelikeFinished()
	{
		CurrentSymbolIndex = StartingSymbolIndex;
	}

	UFUNCTION()
	private void HidePinTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.RelativeLocation = (Math::Lerp(CurrentLocBeforeHide, HiddenLoc, CurrentValue));
	}

	UFUNCTION()
	private void ShowPinTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.RelativeLocation = (Math::Lerp(HiddenLoc, VisibleLoc, CurrentValue));
	}

	UFUNCTION()
	private void OnLeverReset()
	{
		if(WigglePinTimelike.IsPlaying())
				WigglePinTimelike.Stop();

		CurrentLocBeforeHide = MeshRoot.RelativeLocation;
		HidePinTimelike.PlayFromStart();
		OneShotInteractionComp.Disable(this);
		bCorrectSymbol = false;
		bIsPunchedIn = false;
		
		if(CurrentSymbolIndex != StartingSymbolIndex)
		{
			AccRot.SnapTo(MeshRoot.RelativeRotation);
			bShouldResetRotation = true;
		}

		OnRotationComplete.Broadcast(false, CorrectSymbolIndex);
		
		FKeyHolePinParams Params;
		Params.RotatingKeyPin = this;
		UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnKeyPinTimeRanOut(this, Params);
	}

	UFUNCTION()
	private void OnLeverActivated()
	{
		Timer::SetTimer(this, n"ShowPin", ShowPinDelay);
	}

	UFUNCTION()
	void ShowPin()
	{
		ShowPinTimelike.PlayFromStart();

		FKeyHolePinParams Params;
		Params.RotatingKeyPin = this;
		UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnKeyPinReveal(this, Params);
	}

	UFUNCTION()
	private void WigglePinTimelikeUpdate(float CurrentValue)
	{
		float Height = VisibleLoc.Z + CurrentValue;
		MeshRoot.SetRelativeLocation(FVector(0, 0, Height));
	}

	UFUNCTION()
	void OnKeySymbolPunched(bool bCorrectPos, bool bWasPunched)
	{
		if(!bCorrectPos && bWasPunched)
		{
			if(HidePinTimelike.IsPlaying())
				return;

			WigglePinTimelike.PlayFromStart();
			
			FKeyHolePinParams Params;
			Params.RotatingKeyPin = this;
			UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnKeyPinWiggle(this, Params);
		}
		else if(bCorrectPos && bWasPunched)
		{
			if(WigglePinTimelike.IsPlaying())
				WigglePinTimelike.Stop();

			RaisePinTimelike.PlayFromStart();
			OneShotInteractionComp.Disable(this);

			FKeyHolePinParams Params;
			Params.RotatingKeyPin = this;
			UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnKeyPinPuchedInPlace(this, Params);
		}

		BP_PlayPunchShake();
	}

	UFUNCTION(BlueprintEvent)
	void BP_PlayPunchShake(){}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshRoot.SetRelativeRotation(GetPinRotationBasedOnIndex(CurrentSymbolIndex));
	}

	FRotator GetPinRotationBasedOnIndex(int Index)
	{
		switch(Index)
		{
			case 0:
			return FRotator(0, -90, 0);

			case 1:
			return FRotator(0, 0, 0);

			case 2:
			return FRotator(0, 90, 0);

			case 3:
			return FRotator(0, -180, 0);

			default:
			return FRotator::ZeroRotator;
		}
	}

	UFUNCTION()
	private void OnOneShotStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		if(!Player.IsZoe())
			return;
		
		FKeyHolePinParams Params;
		Params.RotatingKeyPin = this;
		UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnKeyPinInteractedWith(this, Params);
		
		if(!Player.HasControl())
			return;
		
		Player.SetActorVelocity(FVector::ZeroVector);

		UTundra_IcePalace_RotatingKeyPinComponent::GetOrCreate(Player).ActiveKeyPin = this;

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(UTundraPlayerFairyComponent::Get(Game::Zoe).GetShapeMesh().IsPlayingAnimAsSlotAnimation(OneShotInteractionComp.OneShotShapeSettings[Game::Zoe].SmallShape.Animation))
		{
			if(Game::Zoe.Mesh.CanRequestLocomotion())
				Game::Zoe.RequestLocomotion(n"Movement", this);
		}

		SetWidgetRelativeOffset();

		if(bCurrentlyRotating)
		{
			RotateTimer += DeltaSeconds;
			if(RotateTimer >= RotateTimerDuration)
			{
				bCurrentlyRotating = false;
				RotationComplete();
			}
			
			float Alpha = Math::Saturate(RotateTimer/RotateTimerDuration);
			FQuat NewRot = FQuat::Slerp(StartingRot.Quaternion(), TargetRot.Quaternion(), RotationCurve.GetFloatValue(Alpha));
			MeshRoot.SetRelativeRotation(NewRot);
		}

		if(bShouldResetRotation)
		{
			AccRot.AccelerateTo(GetPinRotationBasedOnIndex(StartingSymbolIndex), 1, DeltaSeconds);
			MeshRoot.SetRelativeRotation(AccRot.Value);

			ResetTimer += DeltaSeconds;
			if(ResetTimer >= 1)
			{
				ResetTimer = 0;
				bShouldResetRotation = false;
				
				AccRot.SnapTo(GetPinRotationBasedOnIndex(StartingSymbolIndex));
				MeshRoot.SetRelativeRotation(AccRot.Value);
			}
		}
	}

	void SetWidgetRelativeOffset()
	{
		FVector NewRelativeOffset = MeshRoot.RelativeLocation;
		NewRelativeOffset.Z += 275;
		OneShotInteractionComp.WidgetVisualOffset = NewRelativeOffset;
	}

	void RotatePin()
	{
		if(bCurrentlyRotating)
			return;

		if(bIsPunchedIn)
			return;

		int NewCurrentSymbolIndex = (CurrentSymbolIndex + 4 - 1) % 4;
		FRotator NewStartingRot = MeshRoot.RelativeRotation;
		FRotator NewTargetRot = NewStartingRot.Compose(FRotator(0, -90, 0));
		CrumbStartRotating(NewStartingRot, NewTargetRot, NewCurrentSymbolIndex);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartRotating(FRotator NewStartingRot, FRotator NewTargetRot, int NewCurrentSymbolIndex)
	{
		bCorrectSymbol = false;
		RotateTimer = 0;
		CurrentSymbolIndex = NewCurrentSymbolIndex;
		StartingRot = NewStartingRot;
		TargetRot = NewTargetRot;
		bCurrentlyRotating = true;
		BP_RotatePinFF();
	}

	void RotationComplete()
	{
		if(CurrentSymbolIndex == CorrectSymbolIndex)
		{
			bCorrectSymbol = true;
			OnRotationComplete.Broadcast(true, CorrectSymbolIndex);
		}		
		else if(CurrentSymbolIndex == AlmostCorrectSymbolIndex) //Many players try to match the keypin order to the order of which the symbols are presented on the door. It's not correct, but we want to acknowledge that with VO.
		{
			bAlmostCorrectOrder = true;
			OnRotationComplete.Broadcast(false, CorrectSymbolIndex);
		}
		else
		{
			bAlmostCorrectOrder = false;
			OnRotationComplete.Broadcast(false, CorrectSymbolIndex);
		}
	}

	void SetLockPinCompleteState()
	{
		if(WigglePinTimelike.IsPlaying())
				WigglePinTimelike.Stop();

		LockCompletedTimelike.PlayFromStart();
	}

	UFUNCTION()
	private void RaisePinTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation((Math::Lerp(VisibleLoc, RaisedLoc, CurrentValue)));
	}

	UFUNCTION()
	private void LockCompletedTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation((RaisedLoc + FVector(0, 0, CurrentValue)));
	}

	UFUNCTION(BlueprintEvent)
	void BP_RotatePinFF(){}
};