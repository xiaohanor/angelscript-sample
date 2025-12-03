struct FIslandZombieWallDeathActivationParams
{
	FVector EndLocation;
};

class UIslandZombieWallDeathBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UIslandZombieDeathComponent DeathComp;
	UBasicAICharacterMovementComponent MoveComp;
	UIslandPushKnockComponent KnockComp;

	float FlyDuration;
	float HitDuration = 1.0;
	float MaxWallDistance = 1000.0;
	float HitTime;
	FHazeAcceleratedVector AccPush;

	FVector StartLocation;
	FVector EndLocation;

	ABasicAICharacter Character;

	bool HasWall(FIslandZombieWallDeathActivationParams& Params) const
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();
		FVector HeightLoc = Owner.FocusLocation + FVector::UpVector * 100.0;
		FHitResult Result = Trace.QueryTraceSingle(HeightLoc, HeightLoc + DeathComp.DeathDirection * MaxWallDistance);

		if(Result.bBlockingHit)
		{
			Params.EndLocation = Result.Location - FVector::UpVector * 150.0;
			return true;
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
	bool ShouldActivate(FIslandZombieWallDeathActivationParams& Params) const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!DeathComp.IsDead())
			return false;
		if(DeathComp.DeathType != EIslandZombieDeathType::Pushing)
			return false;
		if(!HasWall(Params))
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
	void OnActivated(FIslandZombieWallDeathActivationParams Params)
	{
		Super::OnActivated();
		DeathComp.StartDeath();			
		StartLocation = Owner.ActorCenterLocation;
		HitTime = 0.0;
		EndLocation = Params.EndLocation;
		FlyDuration = StartLocation.Distance(EndLocation) * 0.0005;
		AccPush.Value = Owner.ActorLocation;
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
			AccPush.AccelerateTo(EndLocation, FlyDuration, DeltaTime);
			DestinationComp.ForceLocation(AccPush.Value);

			if(ActiveDuration >= FlyDuration)
			{
				UIslandZombieWallDamageEffectHandler::Trigger_WallImpact(Owner);
				AnimComp.RequestSubFeature(SubTagAIHurtReactions::KnockbackWallHitDeath, this, HitDuration);	
				HitTime = Time::GetGameTimeSeconds();
				KnockComp.bTriggerImpacts = false;
			}
		}
		
		if(HitTime != 0 && Time::GetGameTimeSince(HitTime) > HitDuration)
		{
			DeactivateBehaviour();
		}
	}
}