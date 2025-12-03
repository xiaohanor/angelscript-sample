UCLASS(Abstract)
class AAITundraGnat : ABasicAICharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatMovementCapability"); 
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatClimbingMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatBeaverSpearMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatLeapEntryMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnatBehaviourCompoundCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnapeGrabbedCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnapeThrownCapabilty");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnapeBallisticCapabilty");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnapeMonkeySlamReactionCapabilty");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraGnapeFallFromTowerCapabilty");

	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(DefaultComponent)
	UTundraGnatComponent GnatComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent MonkeySlamComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"TundraGnatPlayerAnnoyedCapability");

	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent Movecomp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;

	UPROPERTY(DefaultComponent)
	UDealPlayerDamageComponent DealDamageComp;

	int PostSpawnCountDown = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Always go for the tree man girl
		TargetingComponent.SetTarget(Game::Zoe);
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");

		// Tree is mostly static so set control side matching
		// squasher monkey for best fidelity.
		SetActorControlSide(Game::Mio);

		// We can climb anywhere!
		UMovementStandardSettings::SetWalkableSlopeAngle(this, 89.0, this, EHazeSettingsPriority::Defaults);

		Super::BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRespawn()
	{
		// Always go for the tree man girl
		TargetingComponent.SetTarget(Game::Zoe);

		// Respawning gnat is hidden a few frames since it may be repositioned at most two frames after spawn
		AddActorVisualsBlock(this);
		// Do not disable gnat until it has had a chance to reposition
		DisableComp.SetEnableAutoDisable(false);
		PostSpawnCountDown = 3;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (PostSpawnCountDown > 0)
		{
			PostSpawnCountDown--;
			if (PostSpawnCountDown == 0)
			{
				RemoveActorVisualsBlock(this);
				//DisableComp.SetEnableAutoDisable(true); // TODO: Investigate, gnapes will still be disabled after respawn
			}
		}

		// For some reason Zoe does not have a tree guardian component at gnape begin play
		if (GnatComp.TreeGuardianComp == nullptr)
			GnatComp.TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		// Gnats/gnapes that are disabled should always unspawn
		BehaviourComponent.Unspawn();
	}
}
