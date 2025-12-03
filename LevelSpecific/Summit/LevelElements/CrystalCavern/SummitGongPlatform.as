class ASummitGongPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent FruitRoot;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent Acid;

	UPROPERTY(DefaultComponent)
	USummitMeltComponent MeltComp;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeltComp.OnMelted.AddUFunction(this, n"Onmelted");
	}

	UFUNCTION(BlueprintEvent)
	void BP_Onmelted()
	{
	}

	UFUNCTION()
	private void Onmelted()
	{
		USummitGongPlatform_EventHandler::Trigger_MeltEffect(this);
		BP_Onmelted();
	}
};