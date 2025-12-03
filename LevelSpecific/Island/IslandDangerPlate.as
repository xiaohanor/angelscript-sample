UCLASS(Abstract)
class AIslandDangerPlate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent  Collision;

	UPROPERTY(EditAnywhere)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		// Collision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		// if (bIsCompleted)
		// 	return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
				return;
		}

		if(UsableByPlayer == EHazePlayer::Zoe)
		{
			if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
				return;
		}

		Player.DamagePlayerHealth(1);

		// 

		// if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 


	}


	// UFUNCTION()
	// private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	//                        UPrimitiveComponent OtherComp, int OtherBodyIndex)
	// {	
	// 	auto Player = Cast<AHazePlayerCharacter>(OtherActor);
	// 	if (Player == nullptr)
	// 		return;

	// }
};
