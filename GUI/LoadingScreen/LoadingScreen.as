
UCLASS(Abstract)
class ULoadingScreen : UHazeLoadingScreen
{
	UPROPERTY(BindWidget)
	UWidget DownloadBox;
	UPROPERTY(BindWidget)
	UProgressBar DownloadProgressBar;
	UPROPERTY(BindWidget)
	UHazeTextWidget DownloadProgressText;

	UPROPERTY(BindWidget)
	UWidget RemoteInstallBox;

	UPROPERTY(BindWidget)
	UWidget ShaderCompilationBox;
	UPROPERTY(BindWidget)
	UProgressBar ShaderCompilationProgressBar;

	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation ShowLoadingSpinnerAnimation;

	bool bLoadingScreenVisible = false;

	UFUNCTION(BlueprintOverride)
	void OnShowLoadingScreen()
	{
		PlayAnimation(ShowLoadingSpinnerAnimation);
		bLoadingScreenVisible = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnHideLoadingScreen()
	{
		SetVisibility(ESlateVisibility::Collapsed);
		bLoadingScreenVisible = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		SetWidgetZOrderInLayer(500);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (Progress::IsWaitingForStreamingInstall())
		{
			RemoteInstallBox.Visibility = ESlateVisibility::Hidden;
			DownloadBox.Visibility = ESlateVisibility::HitTestInvisible;

			float Progress = Progress::GetStreamingInstallProgress();
			DownloadProgressBar.SetPercent(Progress);
			DownloadProgressText.SetText(FText::FromString(f"{Progress*100 :.0} %"));
		}
		else if (Progress::IsRemoteWaitingForStreamingInstall())
		{
			RemoteInstallBox.Visibility = ESlateVisibility::HitTestInvisible;
			DownloadBox.Visibility = ESlateVisibility::Hidden;
		}
		else
		{
			RemoteInstallBox.Visibility = ESlateVisibility::Hidden;
			DownloadBox.Visibility = ESlateVisibility::Hidden;
		}

		float ShaderProgress = Progress::GetShaderCompilationProgress();
		if (ShaderProgress >= 0.0 && ShaderProgress < 1.0)
		{
			ShaderCompilationBox.Visibility = ESlateVisibility::HitTestInvisible;
			ShaderCompilationProgressBar.SetPercent(ShaderProgress);
		}
		else
		{
			ShaderCompilationBox.Visibility = ESlateVisibility::Collapsed;
		}
	}
};