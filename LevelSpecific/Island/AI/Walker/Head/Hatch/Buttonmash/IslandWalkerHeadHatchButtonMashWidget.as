
UCLASS(Abstract)
class UIslandWalkerHeadHatchButtonMashWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadWrite)
	bool bFailOrSuccessAnimationDone = false;

	UPROPERTY(BlueprintReadOnly)
	float LeftProgressValue = 0.0;
	
	UPROPERTY(BlueprintReadOnly)
	float RightProgressValue = 0.0;

	UPROPERTY(BlueprintReadOnly)
	FName ActionName = ActionNames::Interaction;

	UFUNCTION(BlueprintEvent)
	void BP_Pulse() {}

	UFUNCTION(BlueprintEvent)
	void BP_Success() {}

	UFUNCTION(BlueprintEvent)
	void BP_Fail() {}

	void Pulse()
	{
		BP_Pulse();
	}

	void Success()
	{
		BP_Success();
	}

	void Fail()
	{
		BP_Fail();
	}
}