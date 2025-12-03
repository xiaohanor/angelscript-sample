class UMenuInstallProgressWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UWidget DownloadBox;
	UPROPERTY(BindWidget)
	UProgressBar DownloadProgressBar;
	UPROPERTY(BindWidget)
	UHazeTextWidget ProgressText;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UpdateState();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UpdateState();
	}

	void UpdateState()
	{
		float32 ProgressPct = 1.f;
		bool bShowProgress = Online::GetDisplayInstallProgress(ProgressPct);

		if (bShowProgress)
		{
			DownloadBox.SetVisibility(ESlateVisibility::HitTestInvisible);
			DownloadProgressBar.SetPercent(ProgressPct);
			ProgressText.SetText(FText::FromString(f"{ProgressPct*100 :.0} %"));
		}
		else
		{
			DownloadBox.SetVisibility(ESlateVisibility::Hidden);
		}
	}
};