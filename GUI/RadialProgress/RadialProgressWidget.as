
UCLASS(Abstract)
class URadialProgressWidget : UHazeUserWidget
{
	// Foreground color of the progress circle
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Interp, Category = "Radial Progress")
	FLinearColor CircleColor = FLinearColor::White;

	// Radius where the progress bar starts
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Interp, Category = "Radial Progress")
	float RadiusMinimum = 0.5;

	// Radius where the progress bar ends
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Interp, Category = "Radial Progress")
	float RadiusMaximum = 0.6;
	
	// Falloff factor to blur the edges of the progress bar
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Radial Progress")
	float BarFalloff = 10.0;

	// Falloff factor of the shadow on the progress bar
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Radial Progress")
	float ShadowFalloff = 5.0;

	// Base alpha of the progress bar's shadow
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Radial Progress")
	float ShadowAlpha = 0.5;

	// Current progress to display
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Radial Progress")
	float BarProgress = 0.7;

	// Angle to start rendering the bar at
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Radial Progress")
	float BarStartAngle = 0.0;

	// Angle to end rendering the bar at
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Radial Progress")
	float BarEndAngle = 1.0;

	UPROPERTY(EditDefaultsOnly, BlueprintHidden, AdvancedDisplay, Category = "Radial Progress")
	UMaterialInterface ProgressMaterial;

	UPROPERTY(BindWidget)
	UImage ProgressImage;

	bool bIsDesignTime;

	/**
	 * Update the current progress displayed by this progress bar.
	 */
	UFUNCTION(Category = "Radial Progress")
	void SetProgress(float Progress)
	{
		if (BarProgress == Progress)
			return;

		BarProgress = Progress;
		RefreshProgress();
	}

	/**
	 * Update the start and end angles of this progress bar.
	 */
	UFUNCTION(Category = "Radial Progress")
	void SetBarAngles(float StartAngle, float EndAngle)
	{
		if (StartAngle == BarStartAngle && EndAngle == BarEndAngle)
			return;

		BarStartAngle = StartAngle;
		BarEndAngle = EndAngle;
		RefreshParameters();
	}

	/**
	 * Update the minimum and maximum radius of this progress bar.
	 */
	UFUNCTION(Category = "Radial Progress")
	void SetRadius(float MinRadius, float MaxRadius)
	{
		RadiusMinimum = MinRadius;
		RadiusMaximum = MaxRadius;
		RefreshRadiusMinimum();
		RefreshRadiusMaximum();
	}


	void RefreshParameters()
	{
		UMaterialInstanceDynamic DynamicMaterial = ProgressImage.GetDynamicMaterial();
		if (DynamicMaterial == nullptr)
		{
			ProgressImage.SetBrushFromMaterial(ProgressMaterial);
			DynamicMaterial = ProgressImage.GetDynamicMaterial();
		}
		
		DynamicMaterial.SetScalarParameterValue(n"Falloff", BarFalloff);
		DynamicMaterial.SetScalarParameterValue(n"Min", RadiusMinimum);
		DynamicMaterial.SetScalarParameterValue(n"Max", RadiusMaximum);
		DynamicMaterial.SetScalarParameterValue(n"ShadowFalloff", ShadowFalloff);
		DynamicMaterial.SetScalarParameterValue(n"ShadowAlpha", ShadowAlpha);
		DynamicMaterial.SetVectorParameterValue(n"CircleColor", CircleColor);
		DynamicMaterial.SetScalarParameterValue(n"StartAngle", BarStartAngle);
		DynamicMaterial.SetScalarParameterValue(n"EndAngle", BarEndAngle);
	}

	void RefreshProgress()
	{
		auto DynamicMaterial = ProgressImage.GetDynamicMaterial();
		DynamicMaterial.SetScalarParameterValue(n"Percent", BarProgress);
	}

	void RefreshBarFalloff()
	{
		auto DynamicMaterial = ProgressImage.GetDynamicMaterial();
		DynamicMaterial.SetScalarParameterValue(n"Falloff", BarFalloff);
	}

	UFUNCTION(BlueprintCallable)
	void RefreshRadiusMinimum()
	{
		auto DynamicMaterial = ProgressImage.GetDynamicMaterial();
		DynamicMaterial.SetScalarParameterValue(n"Min", RadiusMinimum);
	}

	UFUNCTION(BlueprintCallable)
	void RefreshRadiusMaximum()
	{
		auto DynamicMaterial = ProgressImage.GetDynamicMaterial();
		DynamicMaterial.SetScalarParameterValue(n"Max", RadiusMaximum);
	}

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		if(!bIsDesignTime)
			return;
		
		auto DynamicMaterial = ProgressImage.GetDynamicMaterial();
		DynamicMaterial.SetScalarParameterValue(n"Max", RadiusMaximum);
		DynamicMaterial.SetScalarParameterValue(n"Min", RadiusMinimum);
		DynamicMaterial.SetVectorParameterValue(n"CircleColor", CircleColor);
	}

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		bIsDesignTime = IsDesignTime;
		ProgressImage.SetBrushFromMaterial(ProgressMaterial);
		RefreshParameters();
		RefreshProgress();
	}

};