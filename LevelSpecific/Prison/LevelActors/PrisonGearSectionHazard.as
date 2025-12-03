UCLASS(Abstract)
class APrisonGearSectionHazard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintCallable)
	void BP_ActivateEventHandler()
	{
		UGearSectionHazardEventHandler::Trigger_Activate(this);
	}

	UFUNCTION(BlueprintCallable)
	void BP_DeactivateEventHandler()
	{
		UGearSectionHazardEventHandler::Trigger_Deactivate(this);
	}
};
