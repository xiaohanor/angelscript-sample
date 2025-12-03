event void DroneClean();

UCLASS(Abstract)
class APrisonDrones_MiniWash : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintCallable)
	void DroneClean(AHazePlayerCharacter Player)
	{
		UDroneOilCoatComponent::Get(Player).Clean();
	}
};
