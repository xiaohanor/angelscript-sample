class AOilRigShipHijackManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UWidgetComponent Widget;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(EditInstanceOnly)
	AOilRigShipHijackPanel LeftPanel;

	UPROPERTY(EditInstanceOnly)
	AOilRigShipHijackPanel RightPanel;

	UPROPERTY(EditInstanceOnly)
	AActor ControlPanelActor;

	UPROPERTY(Transient, VisibleInstanceOnly)
	UTextureRenderTarget2D WidgetRenderTarget;

	UPROPERTY()
	FOilRigShipHijackEvent OnCompleted;

	bool bAllLampsLit = false;
	bool bAnimatedIn = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EffectEvent::LinkActorToReceiveEffectEventsFrom(this, LeftPanel);
		LeftPanel.Manager = this;
		EffectEvent::LinkActorToReceiveEffectEventsFrom(this, RightPanel);
		RightPanel.Manager = this;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (WidgetRenderTarget == nullptr)
		{
			WidgetRenderTarget = Widget.GetRenderTarget();

			if (WidgetRenderTarget != nullptr)
			{
				UStaticMeshComponent StaticMesh = ControlPanelActor.GetComponentByClass(UStaticMeshComponent);
				UMaterialInstanceDynamic DynamicMaterial = StaticMesh.CreateDynamicMaterialInstance(1);
				DynamicMaterial.SetTextureParameterValue(n"Mask", WidgetRenderTarget);
				DynamicMaterial.SetTextureParameterValue(n"DynamicElements_Mask", WidgetRenderTarget);
			}
		}

		auto HijackWidget = Cast<UOilRigShipHijackWidget>(Widget.GetWidget());

		if (LeftPanel.InteractingPlayer != nullptr || RightPanel.InteractingPlayer != nullptr)
		{
			if (!bAnimatedIn)
			{
				HijackWidget.PlayAnimation(HijackWidget.StartUp);
				bAnimatedIn = true;
			}
		}
		else
		{
			if (bAnimatedIn)
			{
				HijackWidget.PlayAnimation(HijackWidget.StartUp, PlayMode = EUMGSequencePlayMode::Reverse);
				bAnimatedIn = false;
			}
		}

		if (bAllLampsLit)
			return;

		if (LeftPanel.AllLampsLit() && RightPanel.AllLampsLit())
			CrumbAllLampsLit();	

		if (HijackWidget != nullptr)
		{
			HijackWidget.bLeftPendulumActive = LeftPanel.bPendulumActive;
			HijackWidget.LeftPendulumAlpha = LeftPanel.PendulumProgress;
			HijackWidget.bRightPendulumActive = RightPanel.bPendulumActive;
			HijackWidget.RightPendulumAlpha = RightPanel.PendulumProgress;

			HijackWidget.LampState.SetNum(10);
			for (int i = 0; i < 5; ++i)
			{
				HijackWidget.LampState[i] = LeftPanel.LampsLit > i;
				HijackWidget.LampState[i+5] = RightPanel.LampsLit > i;
			}
		}
	}

	void Success(AOilRigShipHijackPanel Panel)
	{
		auto HijackWidget = Cast<UOilRigShipHijackWidget>(Widget.GetWidget());
		if (HijackWidget != nullptr)
		{
			if (Panel == LeftPanel)
				HijackWidget.PlayAnimation(HijackWidget.Success_Left);
			else
				HijackWidget.PlayAnimation(HijackWidget.Success_Right);
		}
	}

	void Fail(AOilRigShipHijackPanel Panel)
	{
		auto HijackWidget = Cast<UOilRigShipHijackWidget>(Widget.GetWidget());
		if (HijackWidget != nullptr)
		{
			if (Panel == LeftPanel)
				HijackWidget.PlayAnimation(HijackWidget.Fail_Left);
			else
				HijackWidget.PlayAnimation(HijackWidget.Fail_Right);
		}
	}

	UFUNCTION(DevFunction)
	void CompleteHijack()
	{
		CrumbAllLampsLit();
	}

	UFUNCTION(CrumbFunction)
	void CrumbAllLampsLit()
	{
		if (bAllLampsLit)
			return;

		SetActorTickEnabled(false);

		bAllLampsLit = true;

		LeftPanel.CompleteAll();
		RightPanel.CompleteAll();

		if (Network::IsGameNetworked() && HasControl())
		{
			Timer::SetTimer(this, n"TriggerCompletion", Time::EstimatedCrumbReachedDelay);
		}
		else
		{
			TriggerCompletion();
		}
	}

	UFUNCTION()
	private void TriggerCompletion()
	{
		OnCompleted.Broadcast();

		auto HijackWidget = Cast<UOilRigShipHijackWidget>(Widget.GetWidget());
		if (HijackWidget != nullptr)
		{
			HijackWidget.PlayAnimation(HijackWidget.StartUp, PlayMode = EUMGSequencePlayMode::Reverse);

			HijackWidget.bLeftPendulumActive = false;
			HijackWidget.LeftPendulumAlpha = 0;
			HijackWidget.bRightPendulumActive = false;
			HijackWidget.RightPendulumAlpha = 0;

			HijackWidget.LampState.SetNum(10);
			for (int i = 0; i < 5; ++i)
			{
				HijackWidget.LampState[i] = true;
				HijackWidget.LampState[i+5] = true;
			}
		}

		UOilRigShipHijackManagerEffectEventHandler::Trigger_Completed(this);
	}
}

class UOilRigShipHijackWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage Pendulum_Left;

	UPROPERTY(BindWidget)
	UImage Pendulum_Right;

	UPROPERTY(BindWidget)
	UImage LeftDot1;
	UPROPERTY(BindWidget)
	UImage LeftDot2;
	UPROPERTY(BindWidget)
	UImage LeftDot3;
	UPROPERTY(BindWidget)
	UImage LeftDot4;
	UPROPERTY(BindWidget)
	UImage LeftDot5;

	UPROPERTY(BindWidget)
	UImage RightDot1;
	UPROPERTY(BindWidget)
	UImage RightDot2;
	UPROPERTY(BindWidget)
	UImage RightDot3;
	UPROPERTY(BindWidget)
	UImage RightDot4;
	UPROPERTY(BindWidget)
	UImage RightDot5;

	UPROPERTY(BindWidget)
	UImage FinalDot_Left;
	UPROPERTY(BindWidget)
	UImage FinalDot_Right;
	
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation StartUp;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Fail_Right;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Fail_Left;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Success_Right;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Success_Left;

	TArray<bool> LampState;
	TArray<UImage> LampImages;

	bool bLeftPendulumActive = false;
	float LeftPendulumAlpha = 0.0;
	bool bRightPendulumActive = false;
	float RightPendulumAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		{
			auto PendulumSlot = Cast<UCanvasPanelSlot>(Pendulum_Left.Slot);

			FAnchors Anchors;
			Anchors.Minimum = FVector2D(0.045, 0.43);
			Anchors.Maximum = FVector2D(0.165, 0.57);
			PendulumSlot.SetAnchors(Anchors);

			FMargin Offsets;
			PendulumSlot.SetOffsets(Offsets);
		}

		{
			auto PendulumSlot = Cast<UCanvasPanelSlot>(Pendulum_Right.Slot);

			FAnchors Anchors;
			Anchors.Minimum = FVector2D(1.0 - 0.165, 0.43);
			Anchors.Maximum = FVector2D(1.0 - 0.045, 0.57);
			PendulumSlot.SetAnchors(Anchors);

			FMargin Offsets;
			PendulumSlot.SetOffsets(Offsets);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		LampState.SetNum(10);
		LampImages.SetNum(10);

		LampImages[0] = LeftDot1;
		LampImages[1] = LeftDot2;
		LampImages[2] = LeftDot3;
		LampImages[3] = LeftDot4;
		LampImages[4] = LeftDot5;

		LampImages[5] = RightDot1;
		LampImages[6] = RightDot2;
		LampImages[7] = RightDot3;
		LampImages[8] = RightDot4;
		LampImages[9] = RightDot5;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bLeftPendulumActive)
		{
			Pendulum_Left.Visibility = ESlateVisibility::HitTestInvisible;

			auto PendulumSlot = Cast<UCanvasPanelSlot>(Pendulum_Left.Slot);
			
			float Pos = Math::Lerp(0.38, 0.62, LeftPendulumAlpha);

			FAnchors Anchors = PendulumSlot.GetAnchors();
			Anchors.Minimum.Y = Pos-0.07;
			Anchors.Maximum.Y = Pos+0.07;

			PendulumSlot.SetAnchors(Anchors);
		}
		else
		{
			Pendulum_Left.Visibility = ESlateVisibility::Hidden;
		}

		if (bRightPendulumActive)
		{
			Pendulum_Right.Visibility = ESlateVisibility::HitTestInvisible;

			auto PendulumSlot = Cast<UCanvasPanelSlot>(Pendulum_Right.Slot);
			
			float Pos = Math::Lerp(0.38, 0.62, RightPendulumAlpha);

			FAnchors Anchors = PendulumSlot.GetAnchors();
			Anchors.Minimum.Y = Pos-0.07;
			Anchors.Maximum.Y = Pos+0.07;

			PendulumSlot.SetAnchors(Anchors);
		}
		else
		{
			Pendulum_Right.Visibility = ESlateVisibility::Hidden;
		}

		for (int i = 0; i < LampState.Num(); ++i)
		{
			if (LampImages[i] == nullptr)
				continue;
			
			if (LampState[i])
			{
				LampImages[i].RenderOpacity = Math::FInterpConstantTo(
					LampImages[i].RenderOpacity, 1.0, InDeltaTime, 10
				);
				// LampImages[i].Visibility = ESlateVisibility::Visible;
			}
			else
			{
				LampImages[i].RenderOpacity = Math::FInterpConstantTo(
					LampImages[i].RenderOpacity, 0.0, InDeltaTime, 3
				);
				// LampImages[i].Visibility = ESlateVisibility::Hidden;
			}
		}

		if (LampState[4])
		{
			FinalDot_Left.RenderOpacity = Math::FInterpConstantTo(
				FinalDot_Left.RenderOpacity, 1.0, InDeltaTime, 10
			);
		}
		else
		{
			FinalDot_Left.RenderOpacity = Math::FInterpConstantTo(
				FinalDot_Left.RenderOpacity, 0.0, InDeltaTime, 3
			);
		}

		if (LampState[9])
		{
			FinalDot_Right.RenderOpacity = Math::FInterpConstantTo(
				FinalDot_Right.RenderOpacity, 1.0, InDeltaTime, 10
			);
		}
		else
		{
			FinalDot_Right.RenderOpacity = Math::FInterpConstantTo(
				FinalDot_Right.RenderOpacity, 0.0, InDeltaTime, 3
			);
		}

		// FinalDot_Left.Visibility = LampImages[4].Visibility;
		// FinalDot_Right.Visibility = LampImages[9].Visibility;
	}
}

class UOilRigShipHijackManagerEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Completed() {}
}