class UDarkPortalCrosshairWidget : UCrosshairWidget
{
	UDarkPortalUserComponent UserComp;

	UPROPERTY(BindWidget)
	UImage Widget;

	UPROPERTY(BindWidget)
	UWidget IndicatorWidget;
	
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Ready;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Activate;

	bool bAnimatedReady = false;
	bool bAnimatedLaunch = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UserComp = UDarkPortalUserComponent::Get(Player);
		IndicatorWidget.SetRenderOpacity(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (UserComp.Portal.State == EDarkPortalState::Launch && !UserComp.AnimationData.bIsAiming)
		{
			if (!bAnimatedLaunch && UserComp.AimTargetData.IsValid())
			{
				bAnimatedLaunch = true;
				StopAllAnimations();
				PlayAnimation(Activate);
			}
		}
		else
		{
			bAnimatedLaunch = false;
			if (bAnimatedReady)
			{
				if (!UserComp.AimTargetData.IsValid())
				{
					bAnimatedReady = false;
				}
			}
			else
			{
				if (UserComp.AimTargetData.IsValid())
				{
					StopAllAnimations();
					PlayAnimation(Ready);
					bAnimatedReady = true;
				}
				else
				{
					if (IsPlayingAnimation())
						StopAllAnimations();

					Widget.SetRenderScale(
						Math::Vector2DInterpConstantTo(
							Widget.GetRenderTransform().Scale,
							FVector2D(1, 1),
							InDeltaTime, 4.0
						)
					);
					Widget.SetColorAndOpacity(FLinearColor::White);
					Widget.SetRenderOpacity(
						Math::FInterpConstantTo(
							Widget.RenderOpacity, 1.0, InDeltaTime, 4.0
						)
					);

					IndicatorWidget.SetRenderOpacity(
						Math::FInterpConstantTo(
							IndicatorWidget.RenderOpacity, 0.0, InDeltaTime, 8.0
						)
					);
				}
			}
		}
	}
}