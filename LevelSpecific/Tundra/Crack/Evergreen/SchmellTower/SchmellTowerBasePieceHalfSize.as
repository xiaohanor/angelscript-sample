UCLASS(Abstract)
class ASchmellTowerBasePieceHalfSize : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedRelativeRotation;
	default SyncedRelativeRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(EditAnywhere)
	float RotationSpeedMultiplier = 55.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SyncedRelativeRotation.Value = ActorRelativeRotation;
		SetActorControlSide(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl())
			SyncedRelativeRotation.Value += FRotator(0.0, DeltaTime * RotationSpeedMultiplier, 0.0);

		ActorRelativeRotation = SyncedRelativeRotation.Value;
	}
}