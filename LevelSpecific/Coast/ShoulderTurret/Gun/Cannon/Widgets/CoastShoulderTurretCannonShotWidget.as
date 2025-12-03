class UCoastShoulderTurretCannonShotWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage FilledCircle;

	bool bHasAmmo = true;

	float FilledCircleStartOpacity;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		FilledCircleStartOpacity = FilledCircle.RenderOpacity;
	}

	void RecoverAmmo() 
	{
		FilledCircle.SetRenderOpacity(FilledCircleStartOpacity);
		bHasAmmo = true;
	}

	void SpendAmmo() 
	{
		FilledCircle.SetRenderOpacity(0.0);
		bHasAmmo = false;
	}	
}