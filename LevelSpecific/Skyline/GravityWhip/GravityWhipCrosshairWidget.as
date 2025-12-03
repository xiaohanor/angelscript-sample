struct FGravityWhipCrosshairWidglet
{
	UCanvasPanelSlot Slot;
	UGravityWhipCrosshairTargetWidglet Widget;
	FVector2D ScreenPosition;
	bool bVisible = true;
	bool bShouldBeVisible = false;
	UGravityWhipTargetComponent TargetComponent;
	FVector RelativeLocation = FVector::ZeroVector;
	FVector WorldLocation = FVector::ZeroVector;
}

class UGravityWhipCrosshairTargetWidglet : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent)
	void Show() {}

	UFUNCTION(BlueprintEvent)
	void Hide() {}
}

UCLASS(Abstract)
class UGravityWhipCrosshairWidget : UCrosshairWithAutoAimWidget
{
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Gravity Whip")
	TSubclassOf<UGravityWhipCrosshairTargetWidglet> WidgletClass;

	UPROPERTY(BindWidget)
	UWidget CrosshairWidget;

	UPROPERTY(BindWidget)
	UWidget Crosshair_Normal;
	UPROPERTY(BindWidget)
	UWidget Crosshair_Dragging;
	UPROPERTY(BindWidget)
	UWidget Crosshair_Dragging_DirectionIndicator;
	UPROPERTY(BindWidget)
	UWidget Crosshair_Slinging;
	UPROPERTY(BindWidget)
	UImage SlingCrosshair;
	UPROPERTY(BindWidget)
	UImage SlingDot;
	UPROPERTY(BindWidget)
	UImage SlingAutoAim;

	private UGravityWhipUserComponent UserComp;
	private TArray<FGravityWhipCrosshairWidglet> Widglets;

	private UCrosshairContainer Container;
	private FVector PreviousGrabCenter;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UserComp = UGravityWhipUserComponent::Get(Player);

		AutoAimIndicator.SetRenderOpacity(0.0);

		if (WidgletClass != nullptr)
		{
			for (int i = 0; i < GravityWhip::Grab::MaxNumGrabs; ++i)
			{
				// TODO: Maximum habsch; we're spawning widgets for the crosshair container
				//  which is our parent (... if you ignore the canvas and widget tree)
				Container = Cast<UCrosshairContainer>(Parent.Outer.Outer);

				auto Widget = Widget::CreateWidget(Container, WidgletClass);
				Widget.OverrideWidgetPlayer(Player);
				Widget.SetVisibility(ESlateVisibility::Collapsed);

				auto WidgetSlot = Cast<UCanvasPanelSlot>(Container.PlayerCanvas.AddChild(Widget));
				WidgetSlot.SetAutoSize(true);

				FGravityWhipCrosshairWidglet Widglet;
				Widglet.Widget = Cast<UGravityWhipCrosshairTargetWidglet>(Widget);
				Widglet.Slot = WidgetSlot;
				Widglets.Add(Widglet);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		for (auto& Widglet : Widglets)
		{
			RemoveWidget(Widglet.Widget);
		}
	}

	void OnUpdateCrosshairContainer(float DeltaTime) override
	{
		//if (SceneView::IsFullScreen() || !SceneView::IsViewPointRendered(Player))
		if (!SceneView::IsViewPointRendered(Player))
		{
			for (auto& Widglet : Widglets)
				Widglet.Widget.SetVisibility(ESlateVisibility::Collapsed);

			CrosshairWidget.SetVisibility(ESlateVisibility::Collapsed);
			return;
		}

		for (int WidgletIndex = 0; WidgletIndex < Widglets.Num(); ++WidgletIndex)
		{
			FGravityWhipCrosshairWidglet& Widglet = Widglets[WidgletIndex];
			Widglet.bShouldBeVisible = false;
		}

		if (!UserComp.HasActiveGrab())
		{
			for (int GrabIndex = 0, Count = UserComp.GrabPoints.Num(); GrabIndex < Count; ++GrabIndex)
			{
				const FGravityWhipGrabPoint& GrabPoint = UserComp.GrabPoints[GrabIndex];
				if (GrabPoint.TargetComponent != nullptr && GrabPoint.TargetComponent.bInvisibleTarget)
					continue;

				int FreeIndex = -1;
				int ExistingIndex = -1;

				for (int WidgletIndex = 0; WidgletIndex < Widglets.Num(); ++WidgletIndex)
				{
					FGravityWhipCrosshairWidglet& Widglet = Widglets[WidgletIndex];
					if (Widglet.bVisible)
					{
						if (Widglet.TargetComponent == GrabPoint.TargetComponent)
						{
							ExistingIndex = WidgletIndex;
							break;
						}
					}
					else
					{
						if (FreeIndex == -1)
							FreeIndex = WidgletIndex;
					}
				}

				if (ExistingIndex == -1 && FreeIndex != -1)
				{
					FGravityWhipCrosshairWidglet& Widglet = Widglets[FreeIndex];
					Widglet.TargetComponent = GrabPoint.TargetComponent;
					ExistingIndex = FreeIndex;
				}

				if (ExistingIndex == -1)
					continue;

				FGravityWhipCrosshairWidglet& Widglet = Widglets[ExistingIndex];
				Widglet.bShouldBeVisible = true;
				Widglet.RelativeLocation = GrabPoint.RelativeLocation;
			}
		}

		for (int WidgletIndex = 0; WidgletIndex < Widglets.Num(); ++WidgletIndex)
		{
			FGravityWhipCrosshairWidglet& Widglet = Widglets[WidgletIndex];
			if (Widglet.bShouldBeVisible)
			{
				if (!Widglet.bVisible)
				{
					Widglet.Widget.Visibility = ESlateVisibility::HitTestInvisible;
					Widglet.Widget.Show();
					Widglet.bVisible = true;
				}

				Widglet.Widget.RenderOpacity = Math::FInterpConstantTo(
					Widglet.Widget.RenderOpacity, 1.0,
					DeltaTime, 5.0
				);

				UpdatePosition(Widglet);
			}
			else
			{
				if (Widglet.bVisible)
				{
					Widglet.Widget.Hide();
					Widglet.bVisible = false;
				}

				Widglet.Widget.RenderOpacity = Math::FInterpConstantTo(
					Widglet.Widget.RenderOpacity, 0.0,
					DeltaTime, 10.0
				);

				if (Widglet.Widget.RenderOpacity <= 0.0)
				{
					Widglet.TargetComponent = nullptr;
				}
				else
				{
					UpdatePosition(Widglet);
				}
			}
		}

		if (UserComp.HasActiveGrab())
		{
			if (UserComp.GetPrimaryGrabMode() == EGravityWhipGrabMode::Drag
				|| UserComp.GetPrimaryGrabMode() == EGravityWhipGrabMode::ControlledDrag
				|| UserComp.GetPrimaryGrabMode() == EGravityWhipGrabMode::Control
			)
			{
				Crosshair_Normal.Visibility = ESlateVisibility::Hidden;
				// Crosshair_Dragging.Visibility = ESlateVisibility::Visible;
				Crosshair_Dragging.Visibility = ESlateVisibility::Hidden;
				Crosshair_Slinging.Visibility = ESlateVisibility::Hidden;

				FVector Direction = Player.ViewRotation.UnrotateVector(UserComp.WantedDragDirection);
				Direction.X = 0.0;

				if (Direction.Size() >= 0.1)
				{
					float DirectionAngle = Math::DirectionToAngleDegrees(FVector2D(Direction.Y, -Direction.Z));
					if (Crosshair_Dragging_DirectionIndicator.RenderOpacity <= 0.05)
					{
						Crosshair_Dragging.SetRenderTransformAngle(DirectionAngle);
					}
					else
					{
						Crosshair_Dragging.SetRenderTransformAngle(Math::InterpAngleDegreesConstantTo(
							Crosshair_Dragging.RenderTransformAngle, DirectionAngle,
							DeltaTime, 1500.0
						));
					}

					Crosshair_Dragging_DirectionIndicator.RenderOpacity = Math::FInterpConstantTo(
						Crosshair_Dragging_DirectionIndicator.RenderOpacity, 1.0,
						DeltaTime, 5.0
					);
				}
				else
				{
					Crosshair_Dragging_DirectionIndicator.RenderOpacity = Math::FInterpConstantTo(
						Crosshair_Dragging_DirectionIndicator.RenderOpacity, 0.0,
						DeltaTime, 10.0
					);
				}

				PreviousGrabCenter = UserComp.GrabCenterLocation;
			}
			else if (UserComp.GetPrimaryGrabMode() == EGravityWhipGrabMode::Sling)
			{
				PreviousGrabCenter = FVector::ZeroVector;
				Crosshair_Normal.Visibility = ESlateVisibility::Hidden;
				Crosshair_Dragging.Visibility = ESlateVisibility::Hidden;
				Crosshair_Slinging.Visibility = ESlateVisibility::Visible;
			}
			else
			{
				PreviousGrabCenter = FVector::ZeroVector;
				Crosshair_Normal.Visibility = ESlateVisibility::Visible;
				Crosshair_Dragging.Visibility = ESlateVisibility::Hidden;
				Crosshair_Slinging.Visibility = ESlateVisibility::Hidden;
			}
		}
		else
		{
			PreviousGrabCenter = FVector::ZeroVector;
			Crosshair_Normal.Visibility = ESlateVisibility::Visible;
			Crosshair_Dragging.Visibility = ESlateVisibility::Hidden;
			Crosshair_Slinging.Visibility = ESlateVisibility::Hidden;
		}

		if (bHasAutoAimTarget)
		{
			AutoAimIndicator.SetRenderOpacity(
				Math::FInterpConstantTo(
					AutoAimIndicator.RenderOpacity,
					1.0, DeltaTime, 5.0
				)
			);

			SlingCrosshair.SetRenderOpacity(
				Math::FInterpConstantTo(
					SlingCrosshair.RenderOpacity,
					0.0, DeltaTime, 5.0
				)
			);

			UMaterialInstanceDynamic TargetMaterial = SlingAutoAim.GetDynamicMaterial();
			TargetMaterial.SetScalarParameterValue(n"Time", 
				TargetMaterial.GetScalarParameterValue(n"Time") + DeltaTime * 10
			);
		}
		else
		{
			AutoAimIndicator.SetRenderOpacity(
				Math::FInterpConstantTo(
					AutoAimIndicator.RenderOpacity,
					0.0, DeltaTime, 5.0
				)
			);

			SlingCrosshair.SetRenderOpacity(
				Math::FInterpConstantTo(
					SlingCrosshair.RenderOpacity,
					1.0, DeltaTime, 5.0
				)
			);
		}


		AutoAimScreenPosition = AimTargetScreenPosition;
		Super::OnUpdateCrosshairContainer(DeltaTime);
	}

	private void UpdatePosition(FGravityWhipCrosshairWidglet& Widglet) const
	{
		if (IsValid(Widglet.TargetComponent))
		{
			Widglet.WorldLocation = Widglet.TargetComponent.WorldTransform.TransformPosition(Widglet.RelativeLocation);
		}

		FVector2D ScreenPosition;
		if (SceneView::ProjectWorldToViewpointRelativePosition(Player, Widglet.WorldLocation, ScreenPosition))
		{
			Widglet.ScreenPosition = ScreenPosition;
		}

		FAnchors WidgletAnchors;
		WidgletAnchors.Minimum = Widglet.ScreenPosition;
		WidgletAnchors.Maximum = Widglet.ScreenPosition;

		Widglet.Slot.Anchors = WidgletAnchors;
		Widglet.Slot.Offsets = FMargin();
		Widglet.Slot.Alignment = FVector2D(0.5, 0.5);
		Widglet.Slot.Position = FVector2D(0.0, 0.0);
	}
}