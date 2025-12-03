
class UIslandShieldotronScenepointEntranceBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIHealthComponent HealthComp;
	UScenepointUserComponent ScenepointUserComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIEntranceComponent EntranceComp;
	UIslandShieldotronEntryScenepointComponent Scenepoint;

	UIslandJetpackShieldotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		EntranceComp = UBasicAIEntranceComponent::GetOrCreate(Owner);
		ScenepointUserComp = UScenepointUserComponent::Get(Owner); // not used
		Settings = UIslandJetpackShieldotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (EntranceComp.bHasStartedEntry)
			return false;
		if (EntranceComp.bHasCompletedEntry)
			return false;
		if (Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp) == nullptr)
		 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		UScenepointComponent APoint =  Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp);
		Scenepoint = Cast<UIslandShieldotronEntryScenepointComponent>(APoint);
		if (Scenepoint != nullptr)
			EntranceComp.bHasStartedEntry = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (EntranceComp.bHasCompletedEntry)
			return true;
		if (Scenepoint == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Scenepoint == nullptr)
		{
			DeactivateBehaviour();
			return;
		}

		// Go to scene point!
		float Speed = (Scenepoint != nullptr && Scenepoint.OverrideScenepointEntryMoveSpeed > 0) ? Scenepoint.OverrideScenepointEntryMoveSpeed : Settings.ScenepointEntryMoveSpeed;
		DestinationComp.MoveTowards(Scenepoint.WorldLocation, Speed);

		if (TargetComp.HasValidTarget())
			DestinationComp.RotateTowards(TargetComp.Target);
		else if (TargetComp.IsValidTarget(Game::GetClosestPlayer(Owner.ActorCenterLocation)))
			DestinationComp.RotateTowards(Game::GetClosestPlayer(Owner.ActorCenterLocation));

		// Continue until we're there
		if (DestinationComp.MoveSuccess() || Scenepoint.IsAt(Owner))
		{
			// We're done!
			EntranceComp.bHasCompletedEntry = true;
		}					
		else if (DestinationComp.MoveFailed())
		{
			// Wait a while then try again
			Cooldown.Set(2.0); 
			EntranceComp.bHasCompletedEntry = false;
		}
	}
}

class UIslandShieldotronEntryScenepointComponent : UScenepointComponent
{
	UPROPERTY(EditAnywhere)
	float OverrideScenepointEntryMoveSpeed = 0;	
};

class AIslandJetpackEntryScenepointActor : AScenepointActorBase
{	
	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UIslandShieldotronEntryScenepointComponent ScenepointComponent;

	// Cast to UIslandShieldotronEntryScenepointComponent if necessary.
	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};
}

UScenepointComponent GetEntryScenePoint(UHazeActorRespawnableComponent RespawnComp)
{
	// If we've been assigned a scenepoint when spawned, we use that
	if ((RespawnComp != nullptr) && (RespawnComp.SpawnParameters.Scenepoint != nullptr))
		return RespawnComp.SpawnParameters.Scenepoint;

	return nullptr;
}