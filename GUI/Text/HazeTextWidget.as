
enum EHazeTextSize
{
	Regular,
	Subtitle,
	Tutorial,
	SubHeader,
	Header,
	SmallText,
	ExtraLarge
};

enum EHazeTextColor
{
	Default,
	Disabled,
	Mio,
	Zoe,
	Attention,
	TempSubtitle,
};

enum EHazeTextModifier
{
	None,
	Italic,
};

UCLASS(Abstract)
class UHazeTextWidget : UHazeUserWidget
{
	UPROPERTY(EditAnywhere, Category = "Haze Text", BlueprintSetter = "ChangeText", DisplayName = "Text")
	FText Text;

	UPROPERTY(EditAnywhere, Category = "Haze Text", BlueprintSetter = "ChangeTextSize")
	EHazeTextSize TextSize = EHazeTextSize::Regular;

	UPROPERTY(EditAnywhere, Category = "Haze Text", BlueprintSetter = "ChangeTextColor")
	EHazeTextColor TextColor = EHazeTextColor::Default;

	UPROPERTY(EditAnywhere, Category = "Haze Text", BlueprintSetter = "ChangeTextModifier")
	EHazeTextModifier TextModifier = EHazeTextModifier::None;

	UPROPERTY(EditAnywhere, Category = "Haze Text", BlueprintSetter = "ChangeJustification")
	ETextJustify Justification = ETextJustify::Left;

	UPROPERTY(EditAnywhere, Category = "Haze Text")
	bool bOutline = false;

	UPROPERTY(EditAnywhere, Category = "Haze Text")
	bool bShadow = false;

	UPROPERTY(EditAnywhere, Category = "Haze Text", BlueprintSetter = "ChangeWrap")
	bool bWrap = false;

	UPROPERTY(EditAnywhere, Category = "Haze Text", BlueprintSetter = "ChangeDarkMode")
	bool bDarkMode = false;

	UFUNCTION(BlueprintEvent)
	void BP_Update() {}

	void Update()
	{
		BP_Update();
	}

	void SetText(FText NewText)
	{
		if (!NewText.IdenticalTo(Text))
		{
			Text = NewText;
			Update();
		}
	}

	UFUNCTION(Meta = (BlueprintInternalUseOnly="true"))
	void ChangeText(FText NewText)
	{
		if (!NewText.IdenticalTo(Text))
		{
			Text = NewText;
			Update();
		}
	}

	UFUNCTION(BlueprintCallable, Meta = (BlueprintInternalUseOnly="true"))
	void ChangeTextSize(EHazeTextSize NewSize)
	{
		TextSize = NewSize;
		Update();
	}

	UFUNCTION(BlueprintCallable, Meta = (BlueprintInternalUseOnly="true"))
	void ChangeTextColor(EHazeTextColor NewColor)
	{
		TextColor = NewColor;
		Update();
	}

	UFUNCTION(BlueprintCallable, Meta = (BlueprintInternalUseOnly="true"))
	void ChangeJustification(ETextJustify NewJustify)
	{
		Justification = NewJustify;
		Update();
	}

	UFUNCTION(BlueprintCallable, Meta = (BlueprintInternalUseOnly="true"))
	void ChangeWrap(bool bNewWrap)
	{
		bWrap = bNewWrap;
		Update();
	}

	UFUNCTION(BlueprintCallable, Meta = (BlueprintInternalUseOnly="true"))
	void ChangeDarkMode(bool bNewDarkMode)
	{
		bDarkMode = bNewDarkMode;
		Update();
	}

	UFUNCTION(BlueprintCallable, Meta = (BlueprintInternalUseOnly="true"))
	void ChangeTextModifier(EHazeTextModifier Modifier)
	{
		TextModifier = Modifier;
		Update();
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetCurrentTextColor() const
	{
		if (bDarkMode)
		{
			return FLinearColor::MakeFromHex(0xff190300);
		}
		else
		{
			switch (TextColor)
			{
				case EHazeTextColor::Default:
					return FLinearColor::White;
				case EHazeTextColor::Disabled:
					return FLinearColor::MakeFromHex(0xff242424);
				case EHazeTextColor::Mio:
					return PlayerColor::Mio;
				case EHazeTextColor::Zoe:
					return PlayerColor::Zoe;
				case EHazeTextColor::Attention:
					return FLinearColor::MakeFromHex(0xffffd200);
				case EHazeTextColor::TempSubtitle:
					return FLinearColor::Yellow;
			}
		}
	}
};