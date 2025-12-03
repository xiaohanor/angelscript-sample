class AAdultDragonLevelBoundary : APlayerTrigger
{
	default BrushComponent.LineThickness = 2;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");


	// How fast the steering happens
	UPROPERTY(EditAnywhere, Category = "Level Boundary")
	float SteeringSpeed = 1.6;

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void BeginPlay()
	{
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto BoundsComp = UAdultDragonBoundaryComponent::Get(Player);
		if(BoundsComp != nullptr)
			BoundsComp.InsideBoundaries.Add(this);
	}
	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto BoundsComp = UAdultDragonBoundaryComponent::Get(Player);
		if(BoundsComp != nullptr)
		{
			BoundsComp.InsideBoundaries.RemoveSingleSwap(this);
			BoundsComp.LastBoundaryLeft = this;
		}
	}

};