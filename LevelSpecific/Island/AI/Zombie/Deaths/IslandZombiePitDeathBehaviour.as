struct FIslandZombiePitDeathActivationParams
{
	FVector EndLocation;
};

class UIslandZombiePitDeathBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UIslandZombieDeathComponent DeathComp;
	UBasicAICharacterMovementComponent MoveComp;
	UIslandPushKnockComponent KnockComp;

	float FlyDuration;
	float HitDuration = 1.0;
	float MaxPitDistance = 1000.0;	
	float HitTime;
	FHazeBezierCurve_3CP Bezier;

	FVector StartLocation;
	FVector EndLocation;

	ABasicAICharacter Character;

	int QueryPoints = 4;
	bool HasPit(FIslandZombiePitDeathActivationParams& Params) const
	{
		for(int i = 0; i < QueryPoints; ++i)
		{
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseSphereShape(Character.CapsuleComponent.CapsuleRadius * 2.0);
			float Mult = MaxPitDistance * (i/float(QueryPoints));			
			FVector Location = Owner.ActorLocation + DeathComp.DeathDirection * Mult;
			FHitResult Result = Trace.QueryTraceSingle(Location, Location);

			if(!Result.bBlockingHit)
			{
				Params.EndLocation = Location;
				return true;
			}
		}

		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnockComp = UIslandPushKnockComponent::Get(Owner);
		DeathComp = UIslandZombieDeathComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		Character = Cast<ABasicAICharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandZombiePitDeathActivationParams& Params) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!DeathComp.IsDead())
			return false;
		if(DeathComp.DeathType != EIslandZombieDeathType::Pushing)
			return false;
		if(!HasPit(Params))
			return false;
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandZombiePitDeathActivationParams Params)
	{
		Super::OnActivated();
		DeathComp.StartDeath();			
		StartLocation = Owner.ActorCenterLocation;
		HitTime = 0.0;
		EndLocation = Params.EndLocation;
		FlyDuration = StartLocation.Distance(EndLocation) * 0.001;
		KnockComp.bTriggerImpacts = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		DeathComp.CompleteDeath();
		KnockComp.bTriggerImpacts = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAITags::HurtReactions, SubTagAIHurtReactions::Knockback, EBasicBehaviourPriority::Medium, this);
		DestinationComp.RotateTowards(StartLocation);

		if(HitTime == 0)
		{			
			FVector MidPoint = ((StartLocation + EndLocation) / 2) + FVector(0, 0, StartLocation.Distance(EndLocation) * 0.5);
			DestinationComp.ForceLocation(BezierCurve::GetLocation_1CP(StartLocation, MidPoint, EndLocation, ActiveDuration / FlyDuration));

			if(ActiveDuration >= FlyDuration)
			{
				KnockComp.bTriggerImpacts = false;
				HitTime = Time::GetGameTimeSeconds();
			}
		}
		
		if(HitTime != 0 && Time::GetGameTimeSince(HitTime) > HitDuration)
		{
			DeactivateBehaviour();
		}
	}
}