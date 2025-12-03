class ASummitTeenDragonMovementBreakableActor : ABreakableActor
{
	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent Trigger;
	default Trigger.Shape = FHazeShapeSettings::MakeSphere(200.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Trigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		BreakableComponent.BreakWithDefault();
	}
};