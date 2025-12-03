class AToggleableLights : AStaticMeshActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bActorIsVisualOnly = true;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};