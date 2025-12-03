class ASanctuaryLightWormSocketAssemblyPart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryFloatingSceneComponent FloatingComp;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	UDarkPortalTargetComponent DarkPortalTargetComponent;
	
	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	FTransform AssembledTransform;

	FTransform DisassembledTransform;

	UPROPERTY(EditInstanceOnly)
	bool bInnerCircle = false;
	USceneComponent AttachComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
	}
};