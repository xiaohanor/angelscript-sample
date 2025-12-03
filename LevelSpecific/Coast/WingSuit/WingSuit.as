
class AWingSuit : AHazeActor
{
	access WingSuitComponent = private, UWingSuitPlayerComponent;

	default ActorTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UHazeCharacterSkeletalMeshComponent Mesh; // Has to be character skeletal mesh component since we link it to the player's mesh locomotion requests.

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PointOfInterestLocation;
	default PointOfInterestLocation.RelativeLocation = FVector(300.0, 0.0, 50.0);
		
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedPOIWorldLocation;
	default SyncedPOIWorldLocation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	FVector PointOfInterestCurrentOffset;

	UPROPERTY()
	AHazePlayerCharacter PlayerOwner;

	access:WingSuitComponent
	UFUNCTION(BlueprintEvent)
	void BP_EnableWingsuitTrail() {}

	access:WingSuitComponent
	UFUNCTION(BlueprintEvent)
	void BP_DisableWingsuitTrail(bool bDeactivateImmediately) {}
}

enum EWingSuitRubberBand
{
	Unset,
	Ahead,
	Behind,
}
