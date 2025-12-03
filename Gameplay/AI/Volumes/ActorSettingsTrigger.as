class AActorSettingsTrigger : AActorTrigger
{
	default ActorClasses.Add(ABasicAICharacter);

	UPROPERTY(EditAnywhere)
	UHazeComposableSettings Settings;

	UPROPERTY(EditAnywhere)
	TArray<UHazeComposableSettings> AdditionalSettings;

	UPROPERTY(EditAnywhere)
	EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"ApplySettings");
		OnActorLeave.AddUFunction(this, n"ClearSettings");
	}

	UFUNCTION()
	private void ApplySettings(AHazeActor Actor)
	{
		Actor.ApplySettings(Settings, this, Priority);
		for (UHazeComposableSettings MoreSettings : AdditionalSettings)
		{
			Actor.ApplySettings(MoreSettings, this, Priority);
		}
	}

	UFUNCTION()
	private void ClearSettings(AHazeActor Actor)
	{
		Actor.ClearSettingsByInstigator(this);
	}
}