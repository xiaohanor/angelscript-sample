class UEnforcerTraverseToScenepointEntranceBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default CapabilityTags.Add(n"EnforcerTraversal");

	UScenepointUserComponent ScenepointUserComp;
	UHazeActorRespawnableComponent RespawnComp;
	UScenepointComponent Scenepoint;
	UEnforcerJetpackComponent JetpackComp;
	UArcTraversalComponent TraversalComp;
	UBasicAIEntranceComponent EntranceComp;
	UBasicAITraversalSettings TraversalSettings;
	UEnforcerJetpackSettings JetpackSettings;
	UTraversalManager TraversalManager;
	bool bJetpackIgnited = false;
	float LandedTime;
	FTraversalArc TraversalArc;
	bool bHasBlockedTraversal = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
		ScenepointUserComp = UScenepointUserComponent::Get(Owner);
		JetpackComp = UEnforcerJetpackComponent::Get(Owner);
		TraversalComp = UArcTraversalComponent::Get(Owner);
		JetpackSettings = UEnforcerJetpackSettings::GetSettings(Owner);
		EntranceComp = UBasicAIEntranceComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void OnReset()
	{
		if (bHasBlockedTraversal)
		{
			Owner.UnblockCapabilities(n"EnforcerTraversal", this);
			bHasBlockedTraversal = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(EntranceComp.bHasStartedEntry)
			return false;
		if (EntranceComp.bHasCompletedEntry)
			return false;
		if (Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp) == nullptr)
		 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (Time::GetGameTimeSince(LandedTime) > JetpackSettings.TraverseToScenepointEntranceLandDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		if (!bHasBlockedTraversal)
		{
			Owner.BlockCapabilities(n"EnforcerTraversal", this);
			bHasBlockedTraversal = true;
		}

		Scenepoint = Scenepoint::GetEntryScenePoint(ScenepointUserComp, RespawnComp);
		UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, EBasicBehaviourPriority::Medium, this);
		JetpackComp.StartJetpack();
		bJetpackIgnited = false;
		LandedTime = BIG_NUMBER;

		// Blind traversal for now; assume there are no obstacles.
		// TODO: Fix flying pathfinding if necessary
		TraversalArc.LaunchLocation = Owner.ActorLocation;
		TraversalArc.LandLocation = Scenepoint.WorldLocation;
		TraversalArc.LaunchTangent = Traversal::GetLaunchDirection(Owner.ActorRotation, JetpackSettings.TraverseToScenepointLaunchPitch) * JetpackSettings.TraverseToScenepointLaunchTangentLength;
		TraversalArc.LandTangent = Traversal::GetLaunchDirection(Scenepoint.WorldRotation, -JetpackSettings.TraverseToScenepointLandPitch) * JetpackSettings.TraverseToScenepointLandTangentLength; 

		if (TraversalManager == nullptr)
			TraversalManager = Traversal::GetManager();
		if (TraversalManager != nullptr)
			TraversalArc.LandArea = TraversalManager.GetCachedScenepointArea(Scenepoint);

		EntranceComp.bHasStartedEntry = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UEnforcerJetpackEffectHandler::Trigger_JetpackEnd(Owner);
		JetpackComp.StopJetpack();
		EntranceComp.bHasCompletedEntry = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurTime = Time::GameTimeSeconds;
		if (CurTime < LandedTime)
		{
			// We haven't yet landed
			bool bLanded = false;
			if (TraversalComp.IsAtDestination(TraversalArc.LandLocation))
			{
				// Land!
				bLanded = true;
				LandedTime = CurTime;
				TraversalComp.SetCurrentArea(TraversalArc.LandArea);
			}
			else
			{
				// Continue traversing
				TraversalComp.Traverse(TraversalArc, JetpackSettings.TraverseToScenepointMoveSpeed);
			}

			// Start landing animation some time before actually landing
			if (bLanded || ((JetpackComp.AnimArcAlpha > 0.5) && Owner.ActorLocation.IsWithinDist(TraversalArc.LandLocation, 57.0)))
				AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, SubTagAIJetpackTraverse::Land, EBasicBehaviourPriority::Medium, this, JetpackSettings.TraverseToScenepointEntranceLandDuration);

			if (!bJetpackIgnited && (ActiveDuration > 0.5))
			{
				bJetpackIgnited = true;
				UEnforcerJetpackEffectHandler::Trigger_JetpackTravel(Owner);
			}
		} 

		// Find traversal area if we can
		if ((TraversalManager != nullptr) && (TraversalArc.LandArea == nullptr) && TraversalManager.CanClaimTraversalCheck(this))
		{
			TraversalManager.ClaimTraversalCheck(this);
			TraversalArc.LandArea = TraversalManager.FindTraversalArea(Scenepoint);					
			if (CurTime > LandedTime)
				TraversalComp.SetCurrentArea(TraversalArc.LandArea);
		}

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			TraversalArc.DrawDebug(FLinearColor::Yellow, 0.0);
		}
#endif
	}
}
