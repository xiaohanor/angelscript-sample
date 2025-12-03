class UTundraGnatStartingTauntBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UTundraGnatSettings Settings;
	UTundraGnatComponent GnatComp;
	UAnimInstanceTundraGnat AnimInstance;
	bool bHasTaunted = false;
	float StartTauntTime;
	float TauntDuration;
	FVector TauntDir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GnatComp = UTundraGnatComponent::Get(Owner); 
		Settings = UTundraGnatSettings::GetSettings(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");

		AnimInstance = Cast<UAnimInstanceTundraGnat>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bHasTaunted = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bHasTaunted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > StartTauntTime + TauntDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		StartTauntTime = Math::RandRange(0.5, 0.8);
		TauntDuration = AnimInstance.GetStartingTauntMaxDuration();
		
		TauntDir = (Game::Zoe.ActorLocation - Owner.ActorLocation).RotateAngleAxis(Math::RandRange(-1.0, 1.0) * 60.0, FVector::UpVector);
		
		UTundraGnatEffectEventHandler::Trigger_OnStartingTaunt(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Game::Zoe);
		if (bHasTaunted)
			return; // Stay still while taunting

		// Move some ways, so we don't all bunch up in the same place, then taunt
		DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + TauntDir * 500.0, Settings.EngageMoveSpeed);

		if (ActiveDuration > StartTauntTime)
		{
			bHasTaunted = true;
			AnimComp.RequestFeature(TundraGnatTags::StartingTaunt, EBasicBehaviourPriority::Medium, this);

			// Come to a stop quickly
			UTundraGnatSettings::SetFriction(Owner, 20.0, this);
		}
	}
}
