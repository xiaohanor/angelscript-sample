UCLASS(Abstract)
class UPlayerAdultTailDragonTargetableWidget : UTargetableWidget
{
	UPROPERTY(Meta = (BindWidget))
	UImage CrosshairImage;

	bool bWasInRange = false;


	UFUNCTION(BlueprintEvent)
	void BP_OnEnterTargetableRange(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnBecomeVisible(){}

	void OnTakenFromPool() override
	{
		Super::OnTakenFromPool();
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		bWasInRange = false;
		BP_OnBecomeVisible();	
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(TargetableScore.bPossibleTarget)
		{
			if(!bWasInRange)
			{
				bWasInRange = true;
				BP_OnEnterTargetableRange();	
			}
		}
	}
}