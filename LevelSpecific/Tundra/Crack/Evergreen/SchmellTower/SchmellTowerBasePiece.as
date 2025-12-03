UCLASS(Abstract)
class ASchmellTowerBasePiece : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedLocalRotation;
	default SyncedLocalRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(EditAnywhere)
	bool bShouldNeverRotate = false;

	UPROPERTY(EditAnywhere)
	float SpeedMultiplier = 30;

	UPROPERTY(NotVisible)
	float HorizontalInput;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SyncedLocalRotation.Value = ActorRelativeRotation;

		SetActorControlSide(Game::Zoe);
		if(bShouldNeverRotate)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			SyncedLocalRotation.Value += FRotator(0.0, -HorizontalInput * (SpeedMultiplier * DeltaSeconds), 0.0);
		}

		ActorRelativeRotation = SyncedLocalRotation.Value;
	}
}