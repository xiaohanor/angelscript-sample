UCLASS(Abstract)
class UIslandJetpackWorldSpaceFuelWidget : UHazeUserWidget
{
	AHazePlayerCharacter PlayerOwner;
	UIslandJetpackComponent JetpackComp;
	UIslandJetpackSettings Settings;

	const int WidgetCellCount = 5;

	UFUNCTION(BlueprintPure)
	float GetCurrentFuel()
	{
		return JetpackComp.GetChargeLevel();
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentFuelFractured()
	{
		float Fuel = JetpackComp.GetChargeLevel();
		Fuel *= WidgetCellCount;
		Fuel = Math::CeilToFloat(Fuel); 
		Fuel /= WidgetCellCount;
		return Fuel;
	}

	UFUNCTION(BlueprintPure)
	bool IsBoosting()
	{
		return JetpackComp.bBoosting;
	}

	UFUNCTION(BlueprintPure)
	bool IsRecharging()
	{
		return JetpackComp.bIsRecharging;
	}

	UFUNCTION(BlueprintEvent)
	void OnLand(){}
}