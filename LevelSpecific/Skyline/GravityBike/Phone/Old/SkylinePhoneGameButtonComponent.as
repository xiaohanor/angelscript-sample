event void FSkylinePhoneGameButtonSignature();
event void FSkylinePhoneGameButtonSelected(bool bSelected);

class USkylinePhoneGameButtonComponent : UBoxComponent
{
	default bGenerateOverlapEvents = false;

	UPROPERTY()
	FSkylinePhoneGameButtonSignature OnButtonPressed;

	UPROPERTY()
	FSkylinePhoneGameButtonSignature OnButtonReleased;
};

class USkylinePhoneGameToggleButtonComponent : USkylinePhoneGameButtonComponent
{
	UPROPERTY()
	bool bShouldBeSelected = false;

	UPROPERTY(BlueprintReadOnly)
	bool bCorrect = false;

	UPROPERTY(BlueprintReadOnly)
	bool bSelected = false;

	ASkylinePhoneGameCaptcha CaptchaParent;

	UPROPERTY()
	FSkylinePhoneGameButtonSelected OnButtonSelected;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnButtonPressed.AddUFunction(this, n"HandleButtonPressed");

		CaptchaParent = Cast<ASkylinePhoneGameCaptcha>(Owner);
		if (CaptchaParent != nullptr)
		{
			OnButtonSelected.AddUFunction(CaptchaParent, n"BoxSelected");
		}

		SetHiddenInGame(!bSelected, true);

		if ((!bShouldBeSelected && !bSelected) || (bShouldBeSelected && bSelected))
			bCorrect = true;
	}

	UFUNCTION()
	private void HandleButtonPressed()
	{
		bSelected = !bSelected;

		OnButtonSelected.Broadcast(bSelected);

		SetHiddenInGame(!bSelected, true);

		if ((!bShouldBeSelected && !bSelected) || (bShouldBeSelected && bSelected))
			bCorrect = true;
		else
			bCorrect = false;
	}
};