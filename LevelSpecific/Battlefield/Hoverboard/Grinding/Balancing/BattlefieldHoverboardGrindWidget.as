class UBattlefieldHoverboardGrindWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UWidget IndicatorContainer;

	const float MaxIndicatorAngle = 90.0;

	const float ShakeFrequency = 10.0;

	const float MaxShakeStrength = 3;

	UBattlefieldHoverboardGrindingComponent GrindComp;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		const float ShakeStrength = MaxShakeStrength * Math::Clamp(GrindComp.GrindBalance, 0.5, 1);
		IndicatorContainer.SetRenderTransformAngle(MaxIndicatorAngle * GrindComp.GrindBalance + Math::PerlinNoise1D(Time::GameTimeSeconds * ShakeFrequency) * ShakeStrength);
	}
}