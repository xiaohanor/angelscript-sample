class ASkylinePhoneGameCaptcha : ASkylinePhoneGame
{
	UPROPERTY(DefaultComponent)
	UTextRenderComponent VerifyTextRenderComp;

	UPROPERTY()
	FText VerifyText;

	UPROPERTY()
	FText SkipText;

	int SelectedBoxes = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpdateVerifyText();
	}

	UFUNCTION()
	private void BoxSelected(bool bSelected)
	{
		if (bSelected)
			SelectedBoxes++;
		else
			SelectedBoxes--;
		
		UpdateVerifyText();
	}

	private void UpdateVerifyText()
	{
		if (SelectedBoxes <= 0)
			VerifyTextRenderComp.Text = SkipText;
		else
			VerifyTextRenderComp.Text = VerifyText;
	}
};