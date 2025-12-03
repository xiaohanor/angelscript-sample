event void FOnKeySymbolPunched(bool bCorrectPos, bool bWasPunched);

class ATundra_IcePalace_KeySymbol : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent SymbolMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ExtentionMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonFrameMainRoot;

	UPROPERTY(DefaultComponent, Attach = ButtonFrameMainRoot)
	USceneComponent ButtonFrameRoot01;
	default ButtonFrameRoot01.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = ButtonFrameRoot01)
	UStaticMeshComponent ButtonFrame01;
	default ButtonFrame01.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = ButtonFrameMainRoot)
	USceneComponent ButtonFrameRoot02;
	default ButtonFrameRoot02.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = ButtonFrameRoot02)
	UStaticMeshComponent ButtonFrame02;
	default ButtonFrame02.bAbsoluteScale = true;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor ConnectedDoor;

	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> Meshes;

	UPROPERTY()
	FHazeTimeLike PunchCorrectPositionTimelike;
	default PunchCorrectPositionTimelike.Duration = 1;
	UPROPERTY()
	FHazeTimeLike PunchIncorrectPositionTimelike;
	default PunchIncorrectPositionTimelike.Duration = 1;
	UPROPERTY()
	FHazeTimeLike ResetSymbolTimelike;
	default ResetSymbolTimelike.Duration = 1;
	UPROPERTY()
	FHazeTimeLike RotateFrameTimelike;
	default RotateFrameTimelike.Duration = 1;
	FHazeTimeLike ShowEmissiveColorTimelike;
	default ShowEmissiveColorTimelike.Duration = 1;

	FVector EmissiveColor = FVector(1.434877, 1.583978, 7.0);
	FVector NoColor = FVector::ZeroVector;

	float RotateFrameTimelikeDuration = 0.5;

	UPROPERTY(EditInstanceOnly)
	float FrameRollValueCorrect = 0;

	UPROPERTY(EditInstanceOnly)
	int MaterialIndexToChange = 0;

	UPROPERTY()
	FRuntimeFloatCurve RotateFrameToCorrectPositionCurve;
	UPROPERTY()
	FRuntimeFloatCurve RotateFrameToInitialPositionCurve;

	FRuntimeFloatCurve CurrentFrameRotationCurve;

	FVector EmissiveRight = FVector(0, 25, 25);
	FVector EmissiveWrong = FVector(0, 0, 0);

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent PunchComp;

	UPROPERTY(EditInstanceOnly)
	int SymbolIndex = 0;

	UPROPERTY(EditInstanceOnly)
	ATundra_IcePalace_InsideLockLever Lever;

	FOnKeySymbolPunched OnKeySymbolMoved;

	UPROPERTY(EditInstanceOnly)
	ATundra_IcePalace_RotatingKeyPin ConnectedRotatingKeyPin;

	float CorrectPushAnimationDuration = 0.15;
	float InCorrectPushAnimationDuration = 0.5;

	float PushInAmount = -110;
	bool bPushedInPlace = false;
	bool bCorrectSymbol = false;
	bool bDoorShouldBeEmissive = false;
	bool bDoorIsEmissive = false;
	bool bSymbolEnabled = false;
	bool bFrameRotated = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SymbolMesh.SetStaticMesh(Meshes[SymbolIndex]);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		PunchComp.OnPunch.AddUFunction(this, n"OnPunch");

		PunchCorrectPositionTimelike.BindUpdate(this, n"OnPunchCorrectPositionTimelikeUpdate");
		PunchCorrectPositionTimelike.BindFinished(this, n"PunchCorrectPositionTimelikeFinished");
		PunchIncorrectPositionTimelike.BindUpdate(this, n"OnPunchIncorrectPositionTimelikeUpdate");
		ResetSymbolTimelike.BindUpdate(this, n"ResetSymbolTimelikeUpdate");
		ResetSymbolTimelike.BindFinished(this, n"ResetSymbolTimelikeFinished");
		RotateFrameTimelike.BindUpdate(this, n"RotateFrameTimelikeUpdate");
		RotateFrameTimelike.BindFinished(this, n"RotateFrameTimelikeFinished");
		ShowEmissiveColorTimelike.BindUpdate(this, n"ShowEmissiveColorTimelikeUpdate");

		PunchCorrectPositionTimelike.PlayRate = 1 / CorrectPushAnimationDuration;
		PunchIncorrectPositionTimelike.PlayRate = 1 / InCorrectPushAnimationDuration;
		ResetSymbolTimelike.PlayRate = 1 / CorrectPushAnimationDuration;
		RotateFrameTimelike.PlayRate = 1 / RotateFrameTimelikeDuration;

		Lever.OnLeverActivated.AddUFunction(this, n"OnLeverActivated");
		Lever.OnLeverReset.AddUFunction(this, n"OnLeverReset");

		ConnectedRotatingKeyPin.OnRotationComplete.AddUFunction(this, n"OnKeyPinRotationComplete");
		PunchComp.Disable(this);
		ConnectedDoor.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndexToChange, n"Tint_A_Emissive", NoColor);
	}

	UFUNCTION()
	private void OnKeyPinRotationComplete(bool bCorrectRotation, int StartingIndex)
	{
		RotateFrame(bCorrectRotation);
	}

	UFUNCTION()
	private void RotateFrameTimelikeUpdate(float CurrentValue)
	{
		float FrameRollValue = Math::Lerp(0, FrameRollValueCorrect, CurrentFrameRotationCurve.GetFloatValue(CurrentValue));
		FRotator NewRot;
		NewRot.Roll = FrameRollValue;
		ButtonFrameMainRoot.SetRelativeRotation(NewRot);
	}

	UFUNCTION()
	private void RotateFrameTimelikeFinished()
	{
	
	}

	void RotateFrame(bool bCorrectPos)
	{
		FRuntimeFloatCurve Curve = bCorrectPos ? RotateFrameToCorrectPositionCurve : RotateFrameToInitialPositionCurve;
		CurrentFrameRotationCurve = Curve;

		FKeyHoleFrameParams Params;
		Params.KeySymbol = this;

		if(bCorrectPos && !bFrameRotated)
		{
			Params.bRotatedToCorrectPlace = true;
			UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnKeySymbolFrameMoved(this, Params);
		}
		else if (!bCorrectPos && bFrameRotated)
		{
			Params.bRotatedToCorrectPlace = false;
			UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnKeySymbolFrameMoved(this, Params);
		}

		if(bCorrectPos)
		{
			RotateFrameTimelike.Play();
			bFrameRotated = true;
		}
		else
		{
			RotateFrameTimelike.Reverse();
			bFrameRotated = false;
		}
	}

	UFUNCTION()
	private void OnLeverActivated()
	{
		CrumbResetKeySymbol();
		bCorrectSymbol = false;
		bSymbolEnabled = true;
		HideExtentionMesh(false);
	}

	UFUNCTION()
	private void OnLeverReset()
	{
		DisableSymbol();
		SetConnectedDoorEmissive(false);
		bSymbolEnabled = false;
	}

	UFUNCTION()
	private void OnPunchIncorrectPositionTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector(PushInAmount, 0, 0), CurrentValue));
	}

	UFUNCTION()
	private void PunchCorrectPositionTimelikeFinished()
	{
		if(!PunchCorrectPositionTimelike.IsReversed())
			HideExtentionMesh(true);
	}
	
	UFUNCTION()
	private void OnPunchCorrectPositionTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector(PushInAmount, 0, 0), CurrentValue));
	}

	UFUNCTION()
	private void OnPunch(FVector PlayerLocation)
	{
		if(!HasControl())
			return;

		if(bPushedInPlace)
			return;

		NetCheckIfPunchValid();
	}

	UFUNCTION(NetFunction)
	void NetCheckIfPunchValid()
	{
		if(Network::IsGameNetworked())
		{
			if(HasControl())
				return;
		}

		if(bSymbolEnabled)
			NetOnPunch(ConnectedRotatingKeyPin.bCorrectSymbol);
	}

	UFUNCTION(NetFunction)
	void NetOnPunch(bool bCanPunch)
	{
		if(!HasControl())
		{
			if(bCanPunch)
				ConnectedRotatingKeyPin.bIsPunchedIn = true;
			
			return;
		}

		if(ResetSymbolTimelike.IsPlaying())
			return;

		if(bCanPunch)
		{
			bPushedInPlace = true;
			CrumbCorrectPunch();
		}
		else
		{
			CrumbIncorrectPunch();
		}
	}

	void SetConnectedDoorEmissive(bool bShouldBeEmissive)
	{
		if(bDoorIsEmissive && !bShouldBeEmissive)
			bDoorIsEmissive = false;
		else if(!bDoorIsEmissive && bShouldBeEmissive)
			bDoorIsEmissive = true;
		else
			return;

		bDoorShouldBeEmissive = bShouldBeEmissive;
		ShowEmissiveColorTimelike.PlayFromStart();
	}

	UFUNCTION()
	private void ShowEmissiveColorTimelikeUpdate(float CurrentValue)
	{
		FVector LerpA = bDoorShouldBeEmissive ? NoColor : EmissiveColor;
		FVector LerpB = bDoorShouldBeEmissive ? EmissiveColor : NoColor;
		FVector ColorToUse = Math::Lerp(LerpA, LerpB, CurrentValue);
		ConnectedDoor.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndexToChange, n"Tint_A_Emissive", ColorToUse);
	}

	UFUNCTION(CrumbFunction)
	void CrumbCorrectPunch()
	{
		PunchCorrectPositionTimelike.PlayFromStart();
		PunchComp.Disable(this);
		ConnectedRotatingKeyPin.OnKeySymbolPunched(true, true);
		OnKeySymbolMoved.Broadcast(true, true);
		SetConnectedDoorEmissive(true);

		FKeyHoleSymbolParams Params;
		Params.KeySymbol = this;
		UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnKeySymbolPunchedInPlace(this, Params);
	}

	UFUNCTION(CrumbFunction)
	void CrumbIncorrectPunch()
	{
		PunchIncorrectPositionTimelike.PlayFromStart();
		ConnectedRotatingKeyPin.OnKeySymbolPunched(false, true);
		OnKeySymbolMoved.Broadcast(false, true);

		FKeyHoleSymbolParams Params;
		Params.KeySymbol = this;
		UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnKeySymbolPunchedIncorrectPosition(this, Params);
	}

	UFUNCTION(CrumbFunction)
	void CrumbResetKeySymbol()
	{
		PunchComp.Enable(this);

		if(PunchCorrectPositionTimelike.IsPlaying())
		{
			PunchCorrectPositionTimelike.Stop();
			PunchCorrectPositionTimelike.Reverse();
			bPushedInPlace = false;
		}
		else
		{
			PunchCorrectPositionTimelike.ReverseFromEnd();
			bPushedInPlace = false;
		}
	}

	void DisableSymbol()
	{	
		if(PunchComp.IsDisabled())
			return;

		PunchIncorrectPositionTimelike.Stop();
		PunchCorrectPositionTimelike.Stop();

		ResetSymbolTimelike.PlayFromStart();
		PunchComp.Disable(this);
	}

	void HideExtentionMesh(bool bHide)
	{
		ExtentionMesh.SetHiddenInGame(bHide);
	}

	UFUNCTION()
	private void ResetSymbolTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector(PushInAmount, 0, 0), CurrentValue));
	}

	UFUNCTION()
	private void ResetSymbolTimelikeFinished()
	{
		HideExtentionMesh(true);
	}
};