class UTundraShellyShellBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UTundraShellySettings ShellySettings;
	UBasicAIHealthComponent HealthComp;
	UTundraShellyShellComponent ShellComp;
	AHazeCharacter Character;
	float EnterTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShellySettings = UTundraShellySettings::GetSettings(Cast<AHazeActor>(Owner));
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ShellComp = UTundraShellyShellComponent::Get(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		ShellComp.OnEnter.AddUFunction(this, n"OnEnter");
	}

	UFUNCTION()
	private void OnEnter()
	{
		EnterTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!ShellComp.bShelled)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!ShellComp.bShelled)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Time::GetGameTimeSince(EnterTime) > 10)
		{
			if(ShellComp.bShelled)
				ShellComp.ExitShell();
			DeactivateBehaviour();
		}
	}
}

