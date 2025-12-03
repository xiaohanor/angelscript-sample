UCLASS(Abstract)
class ASummitDecimatorLavaDamageTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UFUNCTION()
	void EnableDamageTrigger()
	{
		BP_EnableDamageTrigger();
	};

	UFUNCTION()
	void DisableDamageTrigger()
	{
		BP_DisableDamageTrigger();
	};

	UFUNCTION(BlueprintEvent)
	void BP_EnableDamageTrigger(){};

	UFUNCTION(BlueprintEvent)
	void BP_DisableDamageTrigger(){};
	
};
