class ASerpentSettingsVolume : AActorTrigger
{
	default ActorClasses.Add(ASerpentHead);
	default SetBrushColor(FLinearColor::LucBlue);
	default BrushComponent.LineThickness = 5.0;

	UPROPERTY(EditAnywhere)
	USerpentMovementSettings MovementSettings;

	UPROPERTY(EditAnywhere)
	float BlendTime = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OnActorEnter");
		OnActorLeave.AddUFunction(this, n"OnActorLeave");
	}

	UFUNCTION()
	private void OnActorEnter(AHazeActor Actor)
	{
		ASerpentHead SerpentHead = Cast<ASerpentHead>(Actor);
		
		if (SerpentHead == nullptr)
			return;

		SerpentHead.ApplySerpentSettingsWithBlend(MovementSettings, BlendTime, this);
	}

	UFUNCTION()
	private void OnActorLeave(AHazeActor Actor)
	{
		ASerpentHead SerpentHead = Cast<ASerpentHead>(Actor);

		if (SerpentHead == nullptr)
			return;

		SerpentHead.ClearSerpentSettingsWithBlend(BlendTime, this);
	}
}