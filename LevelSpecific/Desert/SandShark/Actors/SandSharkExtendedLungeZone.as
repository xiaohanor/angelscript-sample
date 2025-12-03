class ASandSharkExtendedLungeZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeMovablePlayerTriggerComponent TriggerComp;
	default TriggerComp.Shape.Type = EHazeShapeType::Sphere;
	default TriggerComp.Shape.SphereRadius = 500;
	default TriggerComp.EditorLineThickness = 10;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		TriggerComp.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		USandSharkPlayerLungeZoneComponent::Get(Player).AddExtendedLungeZone(this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		USandSharkPlayerLungeZoneComponent::Get(Player).RemoveExtendedLungeZone(this);
	}
};