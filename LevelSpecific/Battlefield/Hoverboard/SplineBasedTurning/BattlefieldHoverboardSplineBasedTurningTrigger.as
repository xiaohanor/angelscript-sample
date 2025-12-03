class ABattlefieldHoverboardSplineBasedTurningTrigger : APlayerTrigger
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	ASplineActor SplineToFollow;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bActivateOnEnter = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDeactivateOnEnter = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bActivateOnLeave = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bDeactivateOnLeave = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxTurningFromSpline = 60.0;

	UPROPERTY(EditAnywhere, Category = "settings")
	float TurningDurationWithInput = 2.0;

	UPROPERTY(EditAnywhere, Category = "settings")
	float TurningDurationWithoutInput = 4.0;

	const FName SplineBasedTurningInstigator = n"SplineBasedTurningInstigator";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);
		
		if(bActivateOnEnter)
			ActivateSheet(Player);
		if(bDeactivateOnEnter)
			DeactivateSheet(Player);
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);
		
		if(bActivateOnLeave)
			ActivateSheet(Player);
		if(bDeactivateOnLeave)
			DeactivateSheet(Player);
	}

	private void ActivateSheet(AHazePlayerCharacter Player)
	{
		auto Comp = UBattlefieldHoverboardSplineBasedTurningComponent::GetOrCreate(Player);
		Comp.SplineActor = SplineToFollow;
		Comp.bIsActive = true;
		Comp.Trigger = this;
	}

	private void DeactivateSheet(AHazePlayerCharacter Player)
	{
		auto Comp = UBattlefieldHoverboardSplineBasedTurningComponent::GetOrCreate(Player);
		Comp.SplineActor = nullptr;
		Comp.bIsActive = false;
		Comp.Trigger = nullptr;
	}
}