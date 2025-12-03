
UCLASS(Abstract)
class UCrosshairWidget : UHazeUserWidget
{
	// How long it takes for the crosshair to fade out
	UPROPERTY(EditDefaultsOnly)
	float FadeOutDuration = 0.25;

	UPROPERTY(EditDefaultsOnly)
	bool bDisableLerpCrosshairPos = false;

	UPROPERTY(EditDefaultsOnly)
	bool bCrosshairIsOverlay = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D StaticCrosshairScreenPosition;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D AutoAimScreenPosition;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D AimTargetScreenPosition;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHasAutoAimTarget = false;

	// Called when the crosshair is first shown
	UFUNCTION(BlueprintEvent)
	void OnCrosshairShown() {}

	// Called when the crosshair starts 'lingering', still on screen but aiming is no longer active
	UFUNCTION(BlueprintEvent)
	void OnCrosshairLingerStarted() {}

	// Called when the crosshair starts to fade out
	UFUNCTION(BlueprintEvent)
	void OnCrosshairFadingOut() {}

	// Called when the crosshair container updates
	void OnUpdateCrosshairContainer(float DeltaTime) {}
};

UCLASS(Abstract)
class UCrosshairWithAutoAimWidget : UCrosshairWidget
{
	default bCrosshairIsOverlay = true;

	UPROPERTY(BindWidget)
	UCanvasPanel RootCanvas;

	UPROPERTY(BindWidget)
	UWidget StaticCrosshair;

	UPROPERTY(BindWidget)
	UWidget AutoAimIndicator;

	void OnUpdateCrosshairContainer(float DeltaTime) override
	{
		auto AutoAimSlot = Cast<UCanvasPanelSlot>(AutoAimIndicator.Slot);

		FAnchors AutoAimAnchors;
		AutoAimAnchors.Minimum = AutoAimScreenPosition;
		AutoAimAnchors.Maximum = AutoAimScreenPosition;

		AutoAimSlot.Anchors = AutoAimAnchors;
		AutoAimSlot.Offsets = FMargin(
			0, 0,
			AutoAimIndicator.GetDesiredSize().X,
			AutoAimIndicator.GetDesiredSize().Y,
		);
		AutoAimSlot.Alignment = FVector2D(0.5, 0.5);
		AutoAimSlot.Position = FVector2D(0.0, 0.0);
	}
};