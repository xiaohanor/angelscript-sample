class AMaxSecurityLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	TArray<AMaxSecurityPressurePlate> PressurePlates;
	UPROPERTY()
	TArray<AMaxSecurityLaserHellDoor> Doors;

	UPROPERTY()
	APlayerTrigger EnterSplineLockTrigger;
	UPROPERTY()
	APlayerTrigger ExitSplineLockTrigger01;
	UPROPERTY()
	APlayerTrigger ExitSplineLockTrigger02;
	UPROPERTY()
	APlayerTrigger ExitSplineLockTrigger03;
	UPROPERTY()
	AHazeCameraActor LaserClimbCamera;
	UPROPERTY()
	ASplineActor LaserClimbSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EnterSplineLockTrigger.OnActorBeginOverlap.AddUFunction(this, n"OnEnterSplineLockTrigger");
		ExitSplineLockTrigger01.OnActorBeginOverlap.AddUFunction(this, n"OnExitSplineLockTrigger");
		ExitSplineLockTrigger02.OnActorBeginOverlap.AddUFunction(this, n"OnExitSplineLockTrigger");
		ExitSplineLockTrigger03.OnActorBeginOverlap.AddUFunction(this, n"OnExitSplineLockTrigger");
	}

	UFUNCTION()
	void LaserHellStartTrackingPlayerDeaths()
	{	
		UPlayerHealthComponent::GetOrCreate(Game::Mio).OnDeathTriggered.AddUFunction(this, n"OnMioDiedLaserHell");
		UPlayerHealthComponent::GetOrCreate(Game::Zoe).OnDeathTriggered.AddUFunction(this, n"OnZoeDiedLaserHell");
	}

	UFUNCTION()
	void LaserHellStopTrackingPlayerDeaths()
	{
		UPlayerHealthComponent::GetOrCreate(Game::Mio).OnDeathTriggered.Unbind(this, n"OnMioDiedLaserHell");
		UPlayerHealthComponent::GetOrCreate(Game::Zoe).OnDeathTriggered.Unbind(this, n"OnZoeDiedLaserHell");
	}

	UFUNCTION()
	void OnMioDiedLaserHell()
	{
		OnPlayerDiedLaserHell(Game::Mio);
	}

	UFUNCTION()
	void OnZoeDiedLaserHell()
	{
		OnPlayerDiedLaserHell(Game::Zoe);
	}

	void OnPlayerDiedLaserHell(AHazePlayerCharacter Player)
	{
		for(auto Plate : PressurePlates)
			Plate.ResetPressurePlate();

		for(auto Door : Doors)
			Door.CloseDoor();

		Player.DeactivateCameraByInstigator(this);
		Player.UnlockMovementFromSpline(this);
	}

	UFUNCTION()
	void ResetAllDoorsAndButtons()
	{
		for(auto Door : Doors)
			Door.CloseDoor();

		for(auto Plate : PressurePlates)
			Plate.ResetPressurePlate();
	}

	UFUNCTION()
	void MakePressurePlatesPressable(bool bPressable)
	{
		for(auto Plate : PressurePlates)
			Plate.MakeButtonsPressable(bPressable);
	}

	UFUNCTION()
	private void OnEnterSplineLockTrigger(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		Player.ActivateCamera(LaserClimbCamera, 2, this);

		if(!Player.HasControl())
			return;
		
		FPlayerMovementSplineLockProperties SplineLockProperties; 
		SplineLockProperties.bConstrainInitialVelocityAlongSpline = true;
		Player.LockPlayerMovementToSpline(LaserClimbSpline, this, LockProperties = SplineLockProperties, EnterSettings = LaserHellClimbSplineLockEnterSettings);
	}

	UFUNCTION()
	private void OnExitSplineLockTrigger(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		Player.DeactivateCameraByInstigator(this);

		if(!Player.HasControl())
			return;
		
		Player.UnlockMovementFromSpline(this);
	}
};

asset LaserHellClimbSplineLockEnterSettings of UPlayerSplineLockEnterSettings
{
	EnterType = EPlayerSplineLockEnterType::SmoothLerp;
	EnterSmoothLerpDuration = 0.5;
}