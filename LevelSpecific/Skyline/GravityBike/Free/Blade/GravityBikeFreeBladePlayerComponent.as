UCLASS(Abstract)
class UGravityBikeFreeBladePlayerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	AHazePlayerCharacter Player;
	UGravityBikeFreeDriverComponent DriverComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AGravityBikeFreeBlade> BladeActorClass;

	AGravityBikeFreeBlade BladeActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
		BladeActor = GetOrCreateBladeActor();
	}

	AGravityBikeFreeBlade GetOrCreateBladeActor()
	{
		if(BladeActor == nullptr)
			BladeActor = SpawnActor(BladeActorClass);

		return BladeActor;
	}
}