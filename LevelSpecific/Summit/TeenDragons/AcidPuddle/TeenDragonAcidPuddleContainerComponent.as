
UCLASS(Abstract)
class UTeenDragonAcidPuddleContainerComponent : UActorComponent
{
	UPROPERTY(Category = "Settings")
	TSubclassOf<ATeenDragonAcidPuddleTrail> TrailClass;

	TArray<ATeenDragonAcidPuddle> OverlappingPuddles;
	float CollectedAcidAlpha = 0;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
}