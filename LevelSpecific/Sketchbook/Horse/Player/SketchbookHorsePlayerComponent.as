UCLASS(Abstract)
class USketchbookHorsePlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASketchbookHorse> HorseClass;

	private AHazePlayerCharacter Player;

	UPROPERTY()
	UForceFeedbackEffect FFBeHorse;

	ASketchbookHorse Horse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	
	}

	void SpawnHorse()
	{
		if(Horse != nullptr)
		{
			Horse.RemoveActorDisable(this);
			return;
		}

		Horse = SpawnActor(HorseClass, Player.ActorLocation, Player.ActorRotation, NAME_None, true);
		Horse.AttachToActor(Player);
		Horse.RootComponent.SetAbsolute(false, true, true);
		FinishSpawningActor(Horse);
		Horse.MakeNetworked(this, 0);
		//Horse.SetActorRotation(FRotator(0, 270, 0));

		Game::Mio.PlayForceFeedback(FFBeHorse,false,false,this,1);
	}

	void DespawnHorse()
	{
		Horse.AddActorDisable(this);
		Game::Mio.PlayForceFeedback(FFBeHorse,false,false,this,1);
	}
};