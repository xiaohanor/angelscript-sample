class ABattlefieldHoverboardMovementVolumeSettings : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	UBattlefieldHoverboardGroundMovementSettings GroundSettings; 
	UPROPERTY(EditAnywhere)
	UBattlefieldHoverboardAirMovementSettings AirSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnActorBeginOverlap.AddUFunction(this, n"OnPlayerBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnPlayerEndOverlap");
	}

	UFUNCTION()
	void OnPlayerBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player != nullptr)
		{
			if (GroundSettings != nullptr)
				Player.ApplySettings(GroundSettings, this);
			if (AirSettings != nullptr)
				Player.ApplySettings(AirSettings, this);
		}
	}

	UFUNCTION()
	private void OnPlayerEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player != nullptr)
			Player.ClearSettingsByInstigator(this);
	}

}