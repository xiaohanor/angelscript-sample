UCLASS(NotBlueprintable)
class UDentistToothCannonComponent : UActorComponent
{
	private AHazePlayerCharacter Player;
	UDentistToothCannonSettings Settings;

	private ADentistCannon Cannon;
	private FTraversalTrajectory LaunchTrajectory;
	private bool bIsLaunched = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Settings = UDentistToothCannonSettings::GetSettings(Player);
	}

	void EnterCannon(ADentistCannon InCannon)
	{
		Cannon = InCannon;
	}

	void Launch(FTraversalTrajectory InLaunchTrajectory)
	{
		LaunchTrajectory = InLaunchTrajectory;
		bIsLaunched = true;
	}

	bool IsLaunched() const
	{
		return bIsLaunched;
	}

	FTraversalTrajectory GetLaunchTrajectory() const
	{
		return LaunchTrajectory;
	}
	
	bool IsInCannon() const
	{
		if(Cannon == nullptr)
			return false;

		return Cannon.IsOccupiedBy(Player);
	}

	ADentistCannon GetCannon() const
	{
		return Cannon;
	}

	bool IsCannonStateActive(EDentistCannonState InState) const
	{
		check(IsInCannon());
		return Cannon.IsStateActive(InState);
	}

	void Reset()
	{
		Cannon = nullptr;
		LaunchTrajectory = FTraversalTrajectory();
		bIsLaunched = false;
	}
};