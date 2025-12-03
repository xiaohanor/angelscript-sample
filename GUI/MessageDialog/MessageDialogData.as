
delegate void FOnMessageDialogOptionChosen();

struct FMessageDialog
{
	UPROPERTY()
	FText Message;
	UPROPERTY()
	TArray<FMessageDialogOption> Options;
	UPROPERTY()
	bool bInstantCloseOnCancel = false;

	void AddOKOption(FOnMessageDialogOptionChosen OnChosen = FOnMessageDialogOptionChosen())
	{
		FMessageDialogOption Option;
		Option.Label = NSLOCTEXT("MessageDialog", "OK", "OK");
		Option.OnChosen = OnChosen;

		// OK is also a cancel option so we can press B to close the message box
		Option.Type = EMessageDialogOptionType::Cancel;

		Options.Add(Option);
	}

	void AddConfirmCancelOptions(FOnMessageDialogOptionChosen OnConfirm, FOnMessageDialogOptionChosen OnCancel)
	{
		FMessageDialogOption ConfirmOption;
		ConfirmOption.Label = NSLOCTEXT("MessageDialog", "Confirm", "Confirm");
		ConfirmOption.OnChosen = OnConfirm;
		Options.Add(ConfirmOption);

		FMessageDialogOption CancelOption;
		CancelOption.Label = NSLOCTEXT("MessageDialog", "Cancel", "Cancel");
		CancelOption.Type = EMessageDialogOptionType::Cancel;
		CancelOption.OnChosen = OnCancel;
		Options.Add(CancelOption);
	}

	void AddOption(FText Label, FOnMessageDialogOptionChosen OnChosen, EMessageDialogOptionType OptionType = EMessageDialogOptionType::Option)
	{
		FMessageDialogOption Option;
		Option.Label = Label;
		Option.OnChosen = OnChosen;
		Option.Type = OptionType;
		Options.Add(Option);
	}

	void AddOption(FMessageDialogOption Option)
	{
		Options.Add(Option);
	}

	void AddCancelOption(FOnMessageDialogOptionChosen OnCancel = FOnMessageDialogOptionChosen())
	{
		FMessageDialogOption CancelOption;
		CancelOption.Label = NSLOCTEXT("MessageDialog", "Cancel", "Cancel");
		CancelOption.Type = EMessageDialogOptionType::Cancel;
		CancelOption.OnChosen = OnCancel;
		Options.Add(CancelOption);
	}
};

enum EMessageDialogOptionType
{
	Option,
	Cancel
};

struct FMessageDialogOption
{
	UPROPERTY()
	FText Label;
	UPROPERTY()
	FText DescriptionText;
	UPROPERTY()
	FOnMessageDialogOptionChosen OnChosen;
	UPROPERTY()
	EMessageDialogOptionType Type = EMessageDialogOptionType::Option;
};