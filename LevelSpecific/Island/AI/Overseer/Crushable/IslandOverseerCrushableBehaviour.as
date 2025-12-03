struct FIslandOverseerCrushableBehaviourParams
{
	AIslandOverseerCrushable Crushable;
}

class UIslandOverseerCrushableBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	AAIIslandOverseer Overseer;
	UIslandOverseerSettings Settings;
	UIslandOverseerTakeDamageComponent TakeDamageComp;
	UIslandOverseerTowardsChaseComponent TowardsChaseComp;

	TArray<AIslandOverseerCrushable> Crushables;
	AIslandOverseerCrushable CurrentCrushable;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Overseer = Cast<AAIIslandOverseer>(Owner);
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		TakeDamageComp = UIslandOverseerTakeDamageComponent::GetOrCreate(Owner);
		TowardsChaseComp = UIslandOverseerTowardsChaseComponent::GetOrCreate(Owner);
		Crushables = TListedActors<AIslandOverseerCrushable>().GetArray();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// CurrentCrushable gets synced at activation
		if(!HasControl())
			return;

		for(AIslandOverseerCrushable Crushable : Crushables)
		{
			if(Crushable == nullptr)
				continue;
			if(Crushable.IsActorDisabled())
				continue;
			if(!CanCrush(Crushable))
				continue;
			CurrentCrushable = Crushable;
		}
	}

	private bool CanCrush(AIslandOverseerCrushable Crushable)
	{
		TArray<FVector> CrushLocations;
		CrushLocations.Add(Overseer.Mesh.GetSocketLocation(n"LeftArm"));
		CrushLocations.Add(Overseer.Mesh.GetSocketLocation(n"RightArm"));

		for(FVector Location : CrushLocations)
		{
			FCollisionShape CrushableShape = FCollisionShape::MakeCapsule(250, 1150);
			FTransform CrushableTransform;
			CrushableTransform.SetLocation(Crushable.ActorLocation + Crushable.ActorForwardVector * 400);

			float Radius = TowardsChaseComp.Speed * 1.6;
			FCollisionShape CrusherShape = FCollisionShape::MakeCapsule(Radius, 1150);
			FTransform CrusherTransform;
			CrusherTransform.SetLocation(Location);

			if(Overlap::QueryShapeOverlap(CrushableShape, CrushableTransform, CrusherShape, CrusherTransform))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandOverseerCrushableBehaviourParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(CurrentCrushable == nullptr)
			return false;
		OutParams.Crushable = CurrentCrushable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 0.5)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandOverseerCrushableBehaviourParams Params)
	{
		Super::OnActivated();
		CurrentCrushable = Params.Crushable;
		TakeDamageComp.Crush(CurrentCrushable.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		CurrentCrushable.Crush();
		UIslandOverseerEventHandler::Trigger_OnCrushableHit(Owner);
		CurrentCrushable = nullptr;
		TakeDamageComp.ResetMoveDamage();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
}