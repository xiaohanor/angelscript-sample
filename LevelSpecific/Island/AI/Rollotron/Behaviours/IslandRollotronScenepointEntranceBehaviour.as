
class UIslandRollotronScenepointEntranceBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";


	UIslandRollotronSettings Settings;
	UBasicAICharacterMovementComponent MoveComp;
	USimpleMovementData Movement;

	UScenepointUserComponent ScenepointUserComp;
	UHazeActorRespawnableComponent RespawnComp;
	UBasicAIEntranceComponent EntranceComp;
	UScenepointComponent Scenepoint;

	FVector CurrentVelocity;
	float Gravity = 982;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		EntranceComp = UBasicAIEntranceComponent::GetOrCreate(Owner);
		ScenepointUserComp = UScenepointUserComponent::Get(Owner);
		Settings = UIslandRollotronSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
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
		Scenepoint = Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp);
		EntranceComp.bHasStartedEntry = true;
				
		Owner.BlockCapabilities(n"GroundMovement", this);
		CurrentVelocity = Trajectory::CalculateVelocityForPathWithHeight(Owner.ActorLocation, Scenepoint.WorldLocation, Gravity, 500.0); // TODO: Settings for gravity scale and height
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (EntranceComp.bHasCompletedEntry)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.UnblockCapabilities(n"GroundMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Continue until we're there
		if (Scenepoint.IsAt(Owner) || CurrentVelocity.Size() < SMALL_NUMBER )
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

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				// Apply gravity with gravity scale manually
				CurrentVelocity -= FVector(0, 0, Gravity) * DeltaTime;
				
				// Set movement velocity
				Movement.AddVelocity(CurrentVelocity);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
		}
	}
}
