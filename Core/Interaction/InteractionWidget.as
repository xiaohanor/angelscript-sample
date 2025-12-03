
UCLASS(Abstract)
class UInteractionWidget : UTargetableWidget
{
	UPROPERTY(BindWidget)
	UWidget MainContainer;

	UPROPERTY(BindWidget)
	UWidget OffscreenArrow;

	UPROPERTY()
	TPerPlayer<FLinearColor> IndicatorTopColor;
	UPROPERTY()
	TPerPlayer<FLinearColor> IndicatorBottomColor;

	private EHazeSelectPlayer CurrentlyShownForPlayer;
	private FHazeAcceleratedVector2D CurrentRenderOffset;
	private bool bIsHiding = false;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		MainContainer.SetRenderOpacity(1.0);
		MainContainer.SetRenderTransform(FWidgetTransform());

		CurrentlyShownForPlayer = GetShowForPlayer();
		bIsHiding = false;
		UpdateShownPlayer();

		if (bIsOnEdgeOfScreen)
			OffscreenArrow.RenderOpacity = 1.0;
		else
			OffscreenArrow.RenderOpacity = 0.0;
	}

	UFUNCTION(BlueprintPure)
	EHazeSelectPlayer GetShowForPlayer()
	{
		switch (UsableByPlayers)
		{
			case EHazeSelectPlayer::Mio:
			case EHazeSelectPlayer::Zoe:
			{
				return UsableByPlayers;
			}

			case EHazeSelectPlayer::Both:
			{
				if (SceneView::IsFullScreen() && !bIsPrimaryTarget)
				{
					return EHazeSelectPlayer::Both;
				}
				else
				{
					if (Player == nullptr || Player.IsMio())
						return EHazeSelectPlayer::Mio;
					else
						return EHazeSelectPlayer::Zoe;
				}
			}

			default:
				if (Player == nullptr || Player.IsMio())
					return EHazeSelectPlayer::Mio;
				else
					return EHazeSelectPlayer::Zoe;
		}
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetShownPlayerTopColor()
	{
		switch (GetShowForPlayer())
		{
			case EHazeSelectPlayer::Mio:
				return IndicatorTopColor[EHazePlayer::Mio];
			case EHazeSelectPlayer::Zoe:
				return IndicatorTopColor[EHazePlayer::Zoe];
			default:
				return PlayerColor::BothPlayers;
		}
	}
	
	UFUNCTION(BlueprintPure)
	FLinearColor GetShownPlayerBottomColor()
	{
		switch (GetShowForPlayer())
		{
			case EHazeSelectPlayer::Mio:
				return IndicatorBottomColor[EHazePlayer::Mio];
			case EHazeSelectPlayer::Zoe:
				return IndicatorBottomColor[EHazePlayer::Zoe];
			default:
				return PlayerColor::BothPlayers;
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsShownForOtherPlayerDisabled()
	{
		switch (UsableByPlayers)
		{
			case EHazeSelectPlayer::Mio:
				return Player == nullptr || !Player.IsMio();
			case EHazeSelectPlayer::Zoe:
				return Player != nullptr && !Player.IsZoe();
			default:
				return false;
		}
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void UpdateShownPlayer() {}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
		bIsHiding = true;
	}

	void UpdateWidgetHiding(float DeltaTime)
	{
		float Opacity = MainContainer.GetRenderOpacity();
		Opacity = Math::FInterpConstantTo(Opacity, 0.0, DeltaTime, 5.0);
		MainContainer.SetRenderOpacity(Opacity);

		FWidgetTransform Transform = MainContainer.GetRenderTransform();
		Transform.Scale = Math::Vector2DInterpConstantTo(Transform.Scale, FVector2D(0.1, 0.1), DeltaTime, 5.0);
		MainContainer.SetRenderTransform(Transform);

		if (Opacity <= 0.0)
		{
			bIsHiding = false;
			FinishRemovingWidget();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		// Handle fullscreen scenarios where two widgets for the same interaction are overlapping
		FVector2D TargetRenderOffset;
		if (SceneView::IsFullScreen())
		{
			if (OtherPlayerWidgetState == ETargetableWidgetOtherPlayerState::NotVisible
				|| UsableByPlayers != EHazeSelectPlayer::Both)
			{
				// This is the only widget for this interaction
				SetRenderOpacity(1.0);
			}
			else if (bIsPrimaryTarget)
			{
				if (OtherPlayerWidgetState == ETargetableWidgetOtherPlayerState::PrimaryTarget)
				{
					// The interaction can currently be used by both players, both sides should be visible
					// and offset to the side
					SetRenderOpacity(1.0);

					FVector2D TargetOffset;
					if (Player.IsMio())
						TargetRenderOffset = FVector2D(-26, 0);
					else
						TargetRenderOffset = FVector2D(26, 0);
				}
				else
				{
					// We are actionable, the other side is not, so we should be visible and they shouldn't
					SetRenderOpacity(1.0);
				}
			}
			else if (OtherPlayerWidgetState == ETargetableWidgetOtherPlayerState::PrimaryTarget)
			{
				// The other side is actionable, and we are not, so we should be hidden
				SetRenderOpacity(0.0);
			}
			else if (OtherPlayerWidgetState == ETargetableWidgetOtherPlayerState::Visible)
			{
				// Both sides are visible. Show the widget for the fullscreen player only and have it be in yellow 
				if (SceneView::FullScreenPlayer == Player)
				{
					SetRenderOpacity(1.0);
				}
				else
				{
					SetRenderOpacity(0.0);
				}
			}
		}
		else
		{
			SetRenderOpacity(1.0);
		}

		// Check if we should update which player to show for
		if (GetShowForPlayer() != CurrentlyShownForPlayer)
		{
			CurrentlyShownForPlayer = GetShowForPlayer();
			UpdateShownPlayer();
		}

		// Update render offset
		CurrentRenderOffset.AccelerateTo(TargetRenderOffset, 0.5, InDeltaTime);
		SetRenderTranslation(CurrentRenderOffset.Value);

		// Update opacity when the widget is getting hidden
		if (bIsHiding)
			UpdateWidgetHiding(InDeltaTime);

		UpdateDirectionArrow(InDeltaTime);
	}

	void UpdateDirectionArrow(float DeltaTime)
	{
		if (bIsOnEdgeOfScreen)
		{
			OffscreenArrow.RenderOpacity = Math::FInterpConstantTo(
				OffscreenArrow.RenderOpacity, 1.0, DeltaTime, 5.0
			);

			float Angle = FVector(EdgeAttachDirection.X, EdgeAttachDirection.Y, 0.0).HeadingAngle();
			OffscreenArrow.SetRenderTransformAngle(Math::RadiansToDegrees(Angle));
		}
		else
		{
			OffscreenArrow.RenderOpacity = Math::FInterpConstantTo(
				OffscreenArrow.RenderOpacity, 0.0, DeltaTime, 5.0
			);
		}
	}
};