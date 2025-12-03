UCLASS(Abstract)
class UGravityBikeFreeCrosshairWidget : UCrosshairWidget
{
	UPROPERTY(BindWidget)
	UOverlay AmmoBarOverlay;

	UPROPERTY(BindWidget)
	URadialProgressWidget LeftAmmoBar;

	UPROPERTY(BindWidget)
	URadialProgressWidget RightAmmoBar;

	UPROPERTY(BindWidget)
	UImage CenterCrosshair;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation OnPickedUpAnimation;

	UPROPERTY(EditDefaultsOnly)
	UCurveLinearColor ColorCurve;

	private TArray<URadialProgressWidget> ProgressBars;

	private AGravityBikeFree GravityBike;
	private UGravityBikeWeaponUserComponent WeaponUserComp;

	float VisualCharge = 0;
	bool bPlayingRechargeAnimation = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		ProgressBars.Add(LeftAmmoBar);
		ProgressBars.Add(RightAmmoBar);

		// Start hidden
		RenderOpacity = 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(GravityBike == nullptr)
			return;

		// Fade everything out during cutscenes
		if(GravityBike.bIsControlledByCutscene)
			RenderOpacity = Math::FInterpConstantTo(RenderOpacity, 0, InDeltaTime, 1);
		else
			RenderOpacity = Math::FInterpConstantTo(RenderOpacity, 1, InDeltaTime, 1);

		// Interp the charge smoothly over time
		VisualCharge = Math::FInterpTo(VisualCharge, WeaponUserComp.GetCurrentCharge(), InDeltaTime, 5.0);

		// Update the progress
		for(auto ProgressBar : ProgressBars)
		{
			ProgressBar.SetProgress(VisualCharge);
		}
	
		if(!bPlayingRechargeAnimation)
		{
			// Set the color of the crosshair and progress bars based on the charge level
			const FLinearColor Color = ColorCurve.GetLinearColorValue(VisualCharge);
			CenterCrosshair.SetColorAndOpacity(Color);

			for(auto ProgressBar : ProgressBars)
			{
				ProgressBar.SetColorAndOpacity(Color);
			}
		}
	}

	UFUNCTION()
	private void OnWeaponPickupPickedUp()
	{
		PlayAnimation(OnPickedUpAnimation);
	}

	UFUNCTION(BlueprintOverride)
	void OnAnimationStarted(const UWidgetAnimation Animation)
	{
		if(Animation == OnPickedUpAnimation)
			bPlayingRechargeAnimation = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnAnimationFinished(const UWidgetAnimation Animation)
	{
		if(Animation == OnPickedUpAnimation)
			bPlayingRechargeAnimation = false;
	}

	void Initialize(AHazePlayerCharacter InDriver)
	{
		if(GravityBike != nullptr)
			return;

		GravityBike = GravityBikeFree::GetGravityBike(InDriver);
		WeaponUserComp = UGravityBikeWeaponUserComponent::Get(InDriver);
		WeaponUserComp.OnWeaponPickupPickedUp.AddUFunction(this, n"OnWeaponPickupPickedUp");
	}
}