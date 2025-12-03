UCLASS(Abstract)
class ABasicAIWeapon : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Weapon")
	FName AttachSocketOverride = NAME_None;
}
