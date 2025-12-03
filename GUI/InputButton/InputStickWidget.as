class UInputStickWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage StickImage;
	UPROPERTY(BindWidget)
	UImage Arrows;

	UPROPERTY()
	FLinearColor MioMultiplyColor = FLinearColor::MakeFromHex(0xffff75e1);
	UPROPERTY()
	FLinearColor ZoeMultiplyColor = FLinearColor::MakeFromHex(0xffcaf431);
	
	UPROPERTY(EditAnywhere)
	float ArrowScale = 1.6;

	EHazePlayerControllerType DisplayedControllerType;

	AHazePlayerCharacter InputPlayer;
	UHazeInputComponent InputComp;

	UFUNCTION(BlueprintPure)
	EHazePlayerControllerType GetControllerType()
	{
		if (InputComp != nullptr)
			return InputComp.GetControllerType();
		return Lobby::GetMostLikelyControllerType();
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetMultiplyColor() const
	{
		if (Player != nullptr && Player.IsMio())
			return MioMultiplyColor;
		else
			return ZoeMultiplyColor;
	}

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		Arrows.SetRenderScale(FVector2D(ArrowScale, ArrowScale));
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		DisplayedControllerType = GetControllerType();

		InputPlayer = Player;
		InputComp = UHazeInputComponent::Get(InputPlayer);
	}

	UFUNCTION()
	void OnImageUpdated()
	{
		if (Player != nullptr && Player.IsMio())
			StickImage.GetDynamicMaterial().SetVectorParameterValue(n"MultiplyColor", MioMultiplyColor);
		else
			StickImage.GetDynamicMaterial().SetVectorParameterValue(n"MultiplyColor", ZoeMultiplyColor);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnControllerTypeChanged() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (DisplayedControllerType != GetControllerType())
		{
			DisplayedControllerType = GetControllerType();
			BP_OnControllerTypeChanged();
		}

		if (InputPlayer != Player)
		{
			InputPlayer = Player;
			InputComp = UHazeInputComponent::Get(InputPlayer);
		}
	}
};