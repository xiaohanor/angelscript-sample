UCLASS(Abstract)
class ASketchBook_SimpleEnemyManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	int TotalEnemies;

	UFUNCTION()
	void EnemyKilled()
	{
		TotalEnemies--;
		if(TotalEnemies <= 0)
		{
			EnemiesDefeated();
		}
		Print(""+TotalEnemies);
	}

	UFUNCTION(BlueprintEvent)	
	void EnemiesDefeated()
	{

	}

};
