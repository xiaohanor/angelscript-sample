class ASkylineHighwayCarFloating : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkylineHighwayFloatingComponent FloatingComp;
	default FloatingComp.bUseImpostorMeshesAtDistance = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 25000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};