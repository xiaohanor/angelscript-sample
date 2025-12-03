UCLASS(NotBlueprintable)
class UPrisonStealthStunnedComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, Category = "Stunning")
	float StunDuration = 3;

	private AHazeActor HazeOwner;
	private float StunnedUntilTime = -BIG_NUMBER;
	bool bIsStunned = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
	}

	void StartStun()
	{
		if(!Drone::GetSwarmDronePlayer().HasControl())
			return;

		CrumbStartStun();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartStun()
	{
		StunnedUntilTime = Time::GameTimeSeconds + StunDuration;
	}

	void ResetStun()
	{
		if(!Drone::GetSwarmDronePlayer().HasControl())
			return;

		CrumbResetStun();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbResetStun()
	{
		StunnedUntilTime = -BIG_NUMBER;
	}

	UFUNCTION(BlueprintPure)
	bool IsStunned() const
	{
		return bIsStunned;
	}

	bool ShouldBeStunned() const
	{
		return Time::GameTimeSeconds < StunnedUntilTime;
	}

	float GetStunnedUntilTime() const
	{
		if(!IsStunned())
			return 0;

		return StunnedUntilTime;
	}
};