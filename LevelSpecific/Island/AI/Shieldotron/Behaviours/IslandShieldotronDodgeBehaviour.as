
class UIslandShieldotronDodgeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	//default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UIslandForceFieldComponent ForceFieldComp;

	UPathfollowingSettings PathingSettings;

	UIslandShieldotronSettings Settings;
	
	float Radius;

	AIslandRedBlueStickyGrenade CurrentGrenade;

	float ThrownTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);

		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive())
			return;

		if (!Cooldown.IsOver())
			return;

		if (ForceFieldComp.CurrentType == EIslandForceFieldType::MAX)
			return;

		if (CurrentGrenade != nullptr)
			return;
		
		for (AHazePlayerCharacter Player : Game::Players)
		{
			AIslandRedBlueStickyGrenade Grenade = UIslandRedBlueStickyGrenadeUserComponent::Get(Player).Grenade;
			USceneComponent Target = Grenade.GetGrenadeTarget();
			
			if (!Grenade.IsGrenadeThrown())
				continue;

			if (Grenade.IsGrenadeAttached())
				continue;

			if (Grenade.IsActorDisabled())
				continue;

			if (Target != nullptr && Target.Owner == Owner)
			{
				CurrentGrenade = Grenade;
				ThrownTime = Time::GameTimeSeconds;
				break;
			}
		}

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		
		// if grenade is incoming
		if (CurrentGrenade == nullptr)
			return false;
		
		if ((ThrownTime + 0.2) < Time::GameTimeSeconds )
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.BlockCapabilities(n"MortarAttack", this);
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::Locomotion, SubTagIslandSecurityMech::Dodge, EBasicBehaviourPriority::High, this);
		ThrownTime = 0.0;
		FVector OwnLoc = Owner.ActorLocation;
		FVector ToGrenade = (CurrentGrenade.ActorLocation - OwnLoc).GetSafeNormal();
		float DodgeDir = Owner.ActorRightVector.DotProduct(ToGrenade) < 0 ? 1.0 : -1.0;
		FVector Side;
		Side = Owner.ActorRightVector * 300 * DodgeDir;
		//Side += Owner.ActorForwardVector * -300.0;
		float CircleDist = OwnLoc.Distance(CurrentGrenade.ActorLocation);		
		StrafeDest = Owner.ActorLocation + Side;
	}
	FVector StrafeDest;

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.UnblockCapabilities(n"MortarAttack", this);
		AnimComp.ClearFeature(this);
		CurrentGrenade = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::Locomotion, SubTagIslandSecurityMech::Dodge, EBasicBehaviourPriority::High, this);
		
		float Speed = 800;
		DestinationComp.MoveTowards(StrafeDest, Speed);
		DestinationComp.RotateTowards(TargetComp.Target);


		//if (Owner.ActorLocation.IsWithinDist(StrafeDest, 10.0))
			//AnimComp.ClearFeature(this);

		if (ActiveDuration > 1.0)
			DeactivateBehaviour();
	}


	private bool CanMove(FVector _StrafeDest)
	{

		FVector StrafeDestNavMesh;
		FVector PathStrafeDest = _StrafeDest + (_StrafeDest - Owner.ActorLocation).GetSafeNormal() * Radius * 4.0;
		if(!Pathfinding::FindNavmeshLocation(PathStrafeDest, 0.0, 100.0, StrafeDestNavMesh))
			return false;

		if(!Pathfinding::StraightPathExists(Owner.ActorLocation, StrafeDestNavMesh))
			return false;

		return true;
	}
	
}