
UCLASS(Abstract)
class UTargetableWidget : UPooledWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTargetableResult TargetableScore;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FName TargetableCategory;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsPrimaryTarget = false;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	EHazeSelectPlayer UsableByPlayers;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ETargetableWidgetOtherPlayerState OtherPlayerWidgetState;

	void OnUpdated()
	{
		BP_OnUpdated();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnUpdated() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivationAnimation() {}
};

enum ETargetableWidgetOtherPlayerState
{
	NotVisible,
	Visible,
	PrimaryTarget,
};