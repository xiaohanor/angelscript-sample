class USkylineEnforcerScenepointEntranceBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"Entrance");

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeActorRespawnableComponent RespawnComp;
	USkylineEnforcerScenepointEntranceComponent EntranceComp;
	UEnforcerJetpackComponent JetpackComp;
	UBasicAIRuntimeSplineComponent RuntimeSplineComp;
	UHazeCrumbSyncedFloatComponent ArcAlphaSyncedComp;
	FHazeRuntimeSpline Spline;
	AHazeCharacter Character;

	bool bCompleted;
	float Speed = 1900;
	FVector TargetLocation;
	float LandTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AHazeCharacter>(Owner);
		EntranceComp = USkylineEnforcerScenepointEntranceComponent::GetOrCreate(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		JetpackComp = UEnforcerJetpackComponent::Get(Owner);
		RuntimeSplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);
		ArcAlphaSyncedComp = UHazeCrumbSyncedFloatComponent::Get(Owner, n"JetpackTraversalAlphaSyncedComp");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(bCompleted)
			return;

		if(IsBlockedByTag(n"Entrance"))
			bCompleted = true;
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bCompleted = false;
		if(IsBlockedByTag(n"Entrance"))
			Owner.UnblockCapabilities(n"Entrance", Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(bCompleted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (ActiveDuration > LandTime + 0.8)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		AScenepointActor LandingScenepoint = EntranceComp.LandingScenepoint;
		if(LandingScenepoint == nullptr)
		{
			bCompleted = true;
			DeactivateBehaviour();
			return;
		}

		Spline = FHazeRuntimeSpline();
		FVector Direction = (LandingScenepoint.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		FVector MidPoint = (Owner.ActorLocation + LandingScenepoint.ActorLocation) / 2;
		MidPoint += Direction * -500;
		MidPoint += Direction.Rotation().RightVector * -750;
		MidPoint.Z = Owner.ActorLocation.Z + 100;
		Spline.AddPoint(Owner.ActorLocation);
		Spline.AddPoint(MidPoint);
		TargetLocation = LandingScenepoint.ActorLocation;
		Spline.AddPoint(TargetLocation);
		RuntimeSplineComp.SetSpline(Spline);
		LandTime = BIG_NUMBER;

		JetpackComp.StartJetpack();
		UEnforcerJetpackEffectHandler::Trigger_JetpackStart(Owner);

		ArcAlphaSyncedComp.Value = 0.0;
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JetpackTraverse, SubTagAIJetpackTraverse::Launch, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompleted = true;
		JetpackComp.StopJetpack();
		UEnforcerJetpackEffectHandler::Trigger_JetpackEnd(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bCompleted)
			return;

		if (ActiveDuration > LandTime)
			return;

		if(RuntimeSplineComp.IsNearEndOfSpline(57.0))
			AnimComp.RequestSubFeature(SubTagAIJetpackTraverse::Land, this);
		else if(RuntimeSplineComp.DistanceAlongSpline > 300.0)
			AnimComp.RequestSubFeature(NAME_None, this);

		FVector LookLocation = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		DestinationComp.RotateTowards(LookLocation);
		RuntimeSplineComp.MoveAlongSpline(Speed);
		
		if(RuntimeSplineComp.IsNearEndOfSpline(1))
		{
			LandTime = ActiveDuration;
		}

		JetpackComp.AnimArcAlpha = RuntimeSplineComp.GetSplineAlpha();
		if (HasControl())
			ArcAlphaSyncedComp.Value = JetpackComp.AnimArcAlpha;
		else
			JetpackComp.AnimArcAlpha = ArcAlphaSyncedComp.Value;
	}
}
