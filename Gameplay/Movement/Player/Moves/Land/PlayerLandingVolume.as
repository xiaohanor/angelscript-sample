class APlayerLandingVolume : AVolume
{
	default BrushColor = FLinearColor(1.0, 0.3, 0.7);
	default BrushComponent.LineThickness = 4.0;

	UPROPERTY(EditAnywhere, Category = Settings)
	EInstigatePriority Priority = EInstigatePriority::Normal;
	/*
		Normal: Use normal rules for fatal landings
		Force: Landing will be fatal, regardless of height or speed
		Avoid: You will never get a fatal landing
	*/
	UPROPERTY(EditAnywhere, Category = Settings)
	EPlayerLandingMode FatalMode = EPlayerLandingMode::Normal;

	/*
		Normal: Use normal rules for stunned landings
		Force: Landing will be stunned, regardless of height or speed. Note: Can still be fatal if mode is set as such
		Avoid: You will never get a stunned landing
	*/
	UPROPERTY(EditAnywhere, Category = Settings, meta = (EditCondition="FatalMode != EPlayerLandingMode::Force"))
	EPlayerLandingMode StunnedMode = EPlayerLandingMode::Normal;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnPlayerBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnPlayerEndOverlap");
	}

	UFUNCTION()
	void OnPlayerBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		UPlayerLandingComponent::GetOrCreate(Player).ApplyLanding(this, Priority, FatalMode, StunnedMode);
	}

	UFUNCTION()
	void OnPlayerEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
			
		UPlayerLandingComponent::GetOrCreate(Player).ClearLanding(this);
	}
}