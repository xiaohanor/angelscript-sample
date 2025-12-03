event void FDeathTrackerOnDeathSignature(AHazeActor Corpse);

class ADeathTrackerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	FName TrackTeam = AITeams::Default;

	UPROPERTY(BlueprintReadOnly)
	FDeathTrackerOnDeathSignature OnTrackedDeath;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "SkullAndBones";
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 40.0);
#endif

	UHazeTeam Team; 

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!IsValid(Team))
		{
			Team = HazeTeam::GetTeam(TrackTeam);
			if (IsValid(Team))
			{
				// Found new team
				for (AHazeActor Member : Team.GetMembers())
				{
					OnJoinedTeam(Member);
				}
				Team.OnJoined.AddUFunction(this, n"OnJoinedTeam");
				Team.OnLeft.AddUFunction(this, n"OnLeftTeam");
			}
		}
	}

	UFUNCTION()
	private void OnJoinedTeam(AHazeActor Member)
	{
		if (Member == nullptr)
			return;
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Member);
		if (HealthComp == nullptr)
			return;
		HealthComp.OnDie.AddUFunction(this, n"OnDeath");
		HealthComp.OnStartDying.AddUFunction(this, n"OnStartDying");
	}

	UFUNCTION()
	private void OnLeftTeam(AHazeActor Member)
	{
		if (Member == nullptr)
			return;
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Member);
		if (HealthComp == nullptr)
			return;
		HealthComp.OnDie.UnbindObject(this);
		HealthComp.OnStartDying.UnbindObject(this);
	}

	UFUNCTION()
	void OnStartDying(AHazeActor ActorBeingKilled)
	{
		OnTrackedDeath.Broadcast(ActorBeingKilled);
	}

	UFUNCTION()
	void OnDeath(AHazeActor ActorBeingKilled)
	{
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(ActorBeingKilled);
		if (!HealthComp.HasStartedDying())
			OnTrackedDeath.Broadcast(ActorBeingKilled); // triggered death without triggering start dying
	}	
};