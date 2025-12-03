
// Move around somewhat when there's nothing better to do
class USkylineGeckoIdleMoveBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USkylineGeckoSettings Settings;
	FVector Destination;
	float PauseTime = BIG_NUMBER;
	FHazeAcceleratedFloat Speed;
	float MaxSpeed;
	ASkylineTorCenterPoint Arena;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		Arena = TListedActors<ASkylineTorCenterPoint>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PauseTime = Settings.IdleMovePauseDuration;
		Destination = GetDestination();
		MaxSpeed = Settings.IdleMoveSpeed * Math::RandRange(0.5, 1.0);
		Speed.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Settings.IdleMoveCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (TargetComp.HasValidTarget())
			DestinationComp.RotateTowards(TargetComp.Target);

		if (ActiveDuration < PauseTime)
			return;

		if (Owner.ActorLocation.IsWithinDist(Destination, 20.0) || 
			((ActiveDuration > PauseTime + 0.5) && (Speed.Value < 10.0)))
		{
			// Stop a while
			PauseTime = ActiveDuration + Settings.IdleMovePauseDuration;
			Destination = GetDestination();	
		}
		else if (Owner.ActorLocation.IsWithinDist(Destination, Settings.IdleMoveSpeed * 0.25))
		{
			// Slow down
			Speed.AccelerateTo(0.0, 1.0, DeltaTime);
		}
		else
		{
			// Speed up
			Speed.AccelerateTo(MaxSpeed, 1.0, DeltaTime);
		}
		DestinationComp.MoveTowardsIgnorePathfinding(Destination, Speed.Value);
	}

	FVector GetDestination() const
	{
		FVector Dest = Owner.ActorLocation + Math::GetRandomPointOnCircle_XY() * Settings.IdleMoveSpeed * Math::RandRange(0.75, 1.5);
		if ((Arena == nullptr) || (Dest.IsWithinDist2D(Arena.ActorLocation, Arena.ArenaRadius)))
			return Dest;
		
		// Move the other way
		Dest = Owner.ActorLocation - (Dest - Owner.ActorLocation);
		return Dest;
	}
}