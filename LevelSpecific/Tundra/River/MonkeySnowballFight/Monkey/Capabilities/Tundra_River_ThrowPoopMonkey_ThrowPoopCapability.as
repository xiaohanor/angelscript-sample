struct FTundraPoopMonkeyThrowPoopActivationParams
{
	AHazePlayerCharacter TargetPlayer;
	float ThrowDelay;
}

class UTundra_River_ThrowPoopMonkey_ThrowPoopCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	ATundra_River_ThrowPoopMonkey Monkey;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ATundra_River_ThrowPoopMonkey>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPoopMonkeyThrowPoopActivationParams& Params) const
	{
		if(Monkey.ClosestPlayerInRange == nullptr)
			return false;

		if(Monkey.ClosestDistSqrToPlayer > Monkey.ThrowingRange * Monkey.ThrowingRange)
			return false;

		if(Time::GameTimeSeconds < Monkey.NextThrowTime)
			return false;

		if(Monkey.State == ETundraPoopMonkeyState::Hit)
			return false;

		Params.TargetPlayer = Monkey.ClosestPlayerInRange;
		Params.ThrowDelay = Math::RandRange(0, 1);
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= Monkey.ThrowPoopDuration)
			return true;

		if(Monkey.State == ETundraPoopMonkeyState::Hit)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPoopMonkeyThrowPoopActivationParams Params)
	{
		if(Monkey.State == ETundraPoopMonkeyState::Hit)
			return;

		Monkey.MeshComp.SetAnimTrigger(n"Throw");
		Monkey.NextThrowTime = Time::GameTimeSeconds + Monkey.ThrowPoopDuration + Params.ThrowDelay;
		Monkey.TargetPlayer = Params.TargetPlayer;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};