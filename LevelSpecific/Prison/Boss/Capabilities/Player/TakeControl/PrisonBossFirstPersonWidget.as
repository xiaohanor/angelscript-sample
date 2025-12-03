UCLASS(Abstract)
class UPrisonBossFirstPersonWidget : UHazeUserWidget
{
	void Grabbed()
	{
		BP_Grabbed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Grabbed() {}

	void Released()
	{
		BP_Released();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Released() {}
}