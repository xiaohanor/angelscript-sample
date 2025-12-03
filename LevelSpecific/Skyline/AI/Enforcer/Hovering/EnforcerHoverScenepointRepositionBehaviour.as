struct FEnforcerHoveringScenepointRepositionParams
{
	bool bUnstuckTeleport = false;
}

class UEnforcerHoverScenepointRepositionBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UEnforcerHoveringSettings HoverSettings; 
	UEnforcerHoveringComponent HoveringComp;
	UEnforcerHoverScenepointManager ScenepointManager;
	TArray<FScenepointContainer> ScenepointContainers;
	ASkylineJetpackCombatZoneManager BillboardManager;

	UScenepointComponent RepositionScenepoint;	
	
	TArray<UScenepointComponent> AvailableScenepoints; 
	float CacheScenepointsTime = 0;

	FVector PrevLoc;
	float StuckDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoverSettings =  UEnforcerHoveringSettings::GetSettings(Owner);
		HoveringComp = UEnforcerHoveringComponent::GetOrCreate(Owner);
		BillboardManager = TListedActors<ASkylineJetpackCombatZoneManager>().GetSingle();
	}

	bool WantsToReposition() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TargetComp.HasVisibleTarget() && (DeactiveDuration < HoverSettings.ScenepointRepositionInterval))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive() || IsBlocked())
			return;

		if (WantsToReposition())
		{
			// Find an available scenepoint	to reposition to
			float LowestScore = BIG_NUMBER; 
			AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
			
			if (Time::GameTimeSeconds > CacheScenepointsTime)
			{
				ScenepointContainers.Empty(ScenepointContainers.Num());
				ScenepointManager = Game::GetSingleton(UEnforcerHoverScenepointManager);
				for (TMapIterator<FName,FScenepointContainer> Slot : ScenepointManager.Scenepoints)
				{
					UHazeTeam Team = HazeTeam::GetTeam(Slot.Key);
					if(Team == nullptr)
						continue;
					if (Team.IsMember(Owner)) 
						ScenepointContainers.Add(Slot.Value);
				}

				AvailableScenepoints.Empty(AvailableScenepoints.Num());
				for (FScenepointContainer ScenepointContainer : ScenepointContainers)
				{
					for (UScenepointComponent Scenepoint : ScenepointContainer.Scenepoints)
					{
						AvailableScenepoints.Add(Scenepoint);
					}
				}
				CacheScenepointsTime = Time::GameTimeSeconds + Math::RandRange(0.5, 2.0);

				// Randomize scenepoint order, since resource constraints may make ordering of scenepoints to test important
				AvailableScenepoints.Shuffle();
			}

			for (UScenepointComponent Scenepoint : AvailableScenepoints)
			{
				if (!Scenepoint.CanUse(Owner))	
					continue;

				if (!ScenepointManager.CheckLineOfSight(PlayerTarget, Scenepoint))
					continue;
				
				// Scenepoint close to both us and target are preferred
				float Score = Scenepoint.WorldLocation.Distance(Owner.ActorLocation);
				Score += Scenepoint.WorldLocation.Distance(PlayerTarget.ActorLocation);

				if (HoveringComp.StuckWhenMovingToScenepoint == Scenepoint)
					Score += 1000000.0;

				if (Score < LowestScore)
				{
					LowestScore = Score;
					RepositionScenepoint = Scenepoint;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Chase when target is not visible
		if (!Super::ShouldActivate())
			return false;
		if (!WantsToReposition())
			return false;
		if (RepositionScenepoint == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FEnforcerHoveringScenepointRepositionParams& OutParams) const
	{
		if (Super::ShouldDeactivate())
		{
			OutParams.bUnstuckTeleport = (HoveringComp.StuckWithNoActionCounter > 1);
			return true;
		}
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		RepositionScenepoint.Use(Owner);
		HoveringComp.HoverScenepoint = RepositionScenepoint;
		HoveringComp.StuckWhenMovingToScenepoint = nullptr;
		StuckDuration = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FEnforcerHoveringScenepointRepositionParams Params)
	{
		Super::OnDeactivated();
		RepositionScenepoint.Release(Owner);
		RepositionScenepoint = nullptr;

		if (Params.bUnstuckTeleport)
		{
			HoveringComp.StuckWithNoActionCounter = 0;			
			FVector RecoverLoc = BillboardManager.ActorLocation - BillboardManager.ActorUpVector * 1000.0 + FVector(0.0, 0.0, 1000.0);
			Owner.TeleportActor(RecoverLoc, Owner.ActorRotation, this);
			Owner.AddMovementImpulse((BillboardManager.ActorUpVector + FVector::UpVector) * 1000.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Owner.ActorLocation.IsWithinDist(RepositionScenepoint.WorldLocation, RepositionScenepoint.Radius))
		{
			// We're there!
			Cooldown.Set(0.5);
			return;
		}

		// Keep moving towards target!
		// TODO: We should not ignore pathfinding, investigate why we can not find a path
		if (StuckDuration > HoverSettings.ScenepointRepositionStuckDuration * 0.5)
			DestinationComp.MoveTowardsIgnorePathfinding(RepositionScenepoint.WorldLocation, HoverSettings.HoverChaseMoveSpeed);
		else
			DestinationComp.MoveTowards(RepositionScenepoint.WorldLocation, HoverSettings.HoverChaseMoveSpeed);

		// Check if we've gotten stuck
		if (PrevLoc.IsWithinDist(Owner.ActorLocation, 40.0))
		{
			StuckDuration += DeltaTime;
		}
		else
		{
			StuckDuration = 0.0;
			PrevLoc = Owner.ActorLocation;
		}
		if (StuckDuration > HoverSettings.ScenepointRepositionStuckDuration)
		{
			Cooldown.Set(0.0);
			HoveringComp.StuckWhenMovingToScenepoint = RepositionScenepoint;
			HoveringComp.StuckWithNoActionCounter++;
			return;
		}
	}
}
