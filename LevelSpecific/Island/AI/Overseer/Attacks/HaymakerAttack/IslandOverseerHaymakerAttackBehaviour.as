
class UIslandOverseerHaymakerAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(n"Attack");
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandOverseerSettings Settings;
	AIslandOverseerSideChaseStopPoint LimitPoint;
	UAnimInstanceIslandOverseer AnimInstance;
	UIslandOverseerHaymakerComponent HaymakerComp;
	UHazeSplineComponent Spline;

	FBasicAIAnimationActionDurations Durations;
	AHazeCharacter Character;
	float ImpactTime;
	FVector PreviousAttackLocation;
	bool bAttacking;

	bool bGroundImpact;
	const float GroundImpactDelay = 0.25;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Character.Mesh.AnimInstance);
		HaymakerComp = UIslandOverseerHaymakerComponent::Get(Owner);

		auto Response = UIslandRedBlueImpactResponseComponent::Get(Owner);
		Response.OnImpactEvent.AddUFunction(this, n"Impact");

		AIslandOverseerSideChaseMoveSplineContainer Container = TListedActors<AIslandOverseerSideChaseMoveSplineContainer>()[0];
		TArray<AActor> Actors;
		Container.GetAttachedActors(Actors);
		Spline = Cast<ASplineActor>(Actors[0]).Spline;
	}

	UFUNCTION()
	private void Impact(FIslandRedBlueImpactResponseParams Data)
	{
		if(bAttacking)
			return;
		ImpactTime = Time::GetGameTimeSeconds();
		DeactivateBehaviour();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(ImpactTime != 0 && Time::GetGameTimeSince(ImpactTime) < 0.5)
			return false;
		return true;
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimInstance.FinalizeDurations(FeatureTagIslandOverseer::Haymaker, NAME_None, Durations);
		AnimComp.RequestAction(FeatureTagIslandOverseer::Haymaker, EBasicBehaviourPriority::Medium, this, Durations);
		PreviousAttackLocation = FVector::ZeroVector;
		bAttacking = false;
		bGroundImpact = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(Durations.IsInActionRange(ActiveDuration))
		{
			bAttacking = true;
			FVector AttackLocation = (Character.Mesh.GetSocketLocation(n"LeftHandIndex1") + Character.Mesh.GetSocketLocation(n"LeftHandPinky1")) / 2;
			if(PreviousAttackLocation == FVector::ZeroVector)
				PreviousAttackLocation = AttackLocation;

			FVector Delta = PreviousAttackLocation - AttackLocation;
			if(!Delta.IsNearlyZero())
			{
				FCollisionShape AttackShape = FCollisionShape::MakeSphere(125);
				FTransform AttackTransform;
				AttackTransform.SetLocation(AttackLocation);

				for(AHazePlayerCharacter Player : Game::Players)
				{
					if(Overlap::QueryShapeSweep(AttackShape, AttackTransform, Delta, Player.CapsuleComponent.GetCollisionShape(), Player.CapsuleComponent.WorldTransform))
						Player.KillPlayer(DeathEffect = HaymakerComp.DeathEffect);
				}
			}

			if(bGroundImpact)
				return;

			if(!Durations.IsInActionRange(ActiveDuration - GroundImpactDelay))
				return;

			bGroundImpact = true;
			FVector ImpactLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(AttackLocation);
			UIslandOverseerEventHandler::Trigger_OnHaymakerImpact(Owner, FIslandOverseerEventHandlerOnHaymakerImpactData(ImpactLocation));
		}
	}
}