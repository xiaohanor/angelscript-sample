UCLASS(Abstract)
class APirateShipTelescope : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent InteractionComp;

	UPROPERTY(EditInstanceOnly)
	APirateShipTelescopeCamera Camera;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto PlayerComp = UPirateShipTelescopePlayerComponent::Get(Player);
		PlayerComp.bIsUsingTelescope = true;
		PlayerComp.Telescope = this;
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto PlayerComp = UPirateShipTelescopePlayerComponent::Get(Player);
		PlayerComp.bIsUsingTelescope = false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPlayerStartUsingTelescope(AHazePlayerCharacter Player, float FocalDistance)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPlayerStopUsingTelescope(AHazePlayerCharacter Player)
	{
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_UpdateFocalDistance(AHazePlayerCharacter Player, float FocalDistance)
	{
	}
};