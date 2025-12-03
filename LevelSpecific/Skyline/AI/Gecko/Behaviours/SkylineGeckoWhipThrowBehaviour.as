class USkylineGeckoWhipThrowBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	default CapabilityTags.Add(SkylineAICapabilityTags::GravityWhippable);

	UGravityWhipResponseComponent WhipResponse;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;
	UGravityWhippableSettings WhippableSettings;
	UGravityWhippableComponent WhippableComp;
	UGravityWhipTargetComponent WhipTargetComp;
	UGravityWhipSlingAutoAimComponent WhipSlingAutoAimComp;
	UBasicAIHealthBarComponent HealthBarComp;
	UHazeActorRespawnableComponent RespawnComp;
	UWallclimbingComponent WallclimbingComp;
	UGravityBladeCombatTargetComponent BladeTargetComp; 

	FVector ThrowImpulse;
	AHazeActor ThrowingActor;
	float ThrowTime;
	FVector PreviousCenterLocation;

	TArray<AActor> HitTargets;

	AHazeCharacter Character;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AHazeCharacter>(Owner);

		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");

		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);		
				
		WhipTargetComp = UGravityWhipTargetComponent::Get(Owner);
		WhipSlingAutoAimComp = UGravityWhipSlingAutoAimComponent::Get(Owner);

		BladeTargetComp = UGravityBladeCombatTargetComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		WhippableSettings = UGravityWhippableSettings::GetSettings(Owner);

		HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
		WallclimbingComp = UWallclimbingComponent::Get(Owner);

		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		HealthBarComp.SetHealthBarEnabled(true);
		WallclimbingComp.DestinationUpVector.Clear(this);
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult, FVector Impulse)
	{
		ThrowTime = Time::GetGameTimeSeconds();
		WhippableComp.bThrown = true;
		WhippableComp.OnThrown.Broadcast();
		ThrowingActor = Cast<AHazeActor>(UserComponent.Owner);
		
		UTargetableComponent PrimaryTarget = UPlayerTargetablesComponent::GetOrCreate(UserComponent.Owner).GetPrimaryTargetForCategory(GravityWhip::Grab::SlingTargetableCategory);
		if(PrimaryTarget != nullptr && PrimaryTarget.Owner != Owner)
			ThrowImpulse = (Cast<AHazeActor>(PrimaryTarget.Owner).FocusLocation - Owner.ActorCenterLocation).GetSafeNormal() * Impulse.Size();			
		else
			ThrowImpulse = Impulse;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!WhippableComp.bThrown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(HealthComp.IsDead())
			return true;
		if(!WhippableComp.bThrown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.SetActorVelocity(ThrowImpulse * WhippableSettings.ThrownForceFactor);
		Owner.BlockCapabilities(n"CrowdRepulsion", this);
		
		WhipTargetComp.Disable(this);
		if (WhipSlingAutoAimComp != nullptr)
			WhipSlingAutoAimComp.Disable(this);
	
		USkylineGeckoEffectHandler::Trigger_OnGravityWhipThrown(Owner);

		PreviousCenterLocation = Owner.ActorCenterLocation;

		HitTargets.Empty();

		HealthBarComp.SetHealthBarEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ThrowImpulse = FVector::ZeroVector;
		WhippableComp.bThrown = false;
		Owner.UnblockCapabilities(n"CrowdRepulsion", this);

		if (HealthComp.IsAlive())
			Owner.ClearSettingsByInstigator(this); // If dead we clear them when respawning instead

		WhipTargetComp.Enable(this);
		if (WhipSlingAutoAimComp != nullptr)
			WhipSlingAutoAimComp.Enable(this);

		ThrowTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhipThrown, SubTagAIGravityWhipThrown::Thrown, EBasicBehaviourPriority::Medium, this);

		FMovementHitResult Obstruction;
		for (FMovementHitResult Impact : MoveComp.AllImpacts)
		{
			if (!Impact.IsValidBlockingHit())
				continue;
			Obstruction = Impact;
			break;
		}
		if(Obstruction.bBlockingHit)
		{
			if(WhippableSettings.bEnableThrownDamage)
			{
				TArray<AActor> Targets;
				if(!HitTargets.Contains(Obstruction.Actor))
					Targets.AddUnique(Obstruction.Actor);

				if(WhippableSettings.ThrownDamageRadius > 0)
				{
					UHazeTeam Team = HazeTeam::GetTeam(GravityWhipTags::GravityWhipThrowTargetTeam);
					for(AHazeActor Member: Team.GetMembers())
					{
						if (Member == nullptr)
							continue;
						if (Member == Owner)
							continue;
						if(Member.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, WhippableSettings.ThrownDamageRadius))
						{
							if(!HitTargets.Contains(Member))
								Targets.AddUnique(Member);
						}
					}					
				}

				for(AActor Target: Targets)
				{
					UGravityWhipThrowResponseComponent ResponseComp = UGravityWhipThrowResponseComponent::Get(Target);
					if(ResponseComp == nullptr)
						continue;

					HitTargets.Add(Target);
					if(Target.HasControl())
						CrumbHit(ResponseComp);
				}

				if (Targets.Num() != 0)
				{
					auto HitStopComp = UCombatHitStopComponent::GetOrCreate(Owner);
					HitStopComp.ApplyHitStop(n"WhipImpact", 0.05);
				}
			}
		}

		if(ShouldDie(Obstruction))
		{
			HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, ThrowingActor);
			DeactivateBehaviour();

			FVector DeathUp = Owner.ActorLocation;
			if (Obstruction.bBlockingHit)
			{
				FEnforcerEffectOnGravityWhipThrowImpactData Data;
				Data.ImpactLocation = Obstruction.Location;
				Data.ImpactNormal = Obstruction.Normal;
				
				// Stick to wall we're thrown at
				DeathUp = Obstruction.ImpactNormal; 
			}
			else if (WallclimbingComp.Navigation != nullptr)
			{
				// Stick to closest climbable surface
				FWallclimbingNavigationFace NearPoly;
				if (WallclimbingComp.Navigation.FindClosestNavmeshPoly(Owner.ActorLocation, NearPoly))
					DeathUp = NearPoly.Normal;
			}
			 
			WallclimbingComp.DestinationUpVector.Apply(DeathUp, this, EInstigatePriority::High);

			// Skip pathfinding movement until we respawn
			UPathfollowingSettings::SetIgnorePathfinding(Owner, true, this, EHazeSettingsPriority::Script);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHit(UGravityWhipThrowResponseComponent ResponseComp)
	{
		ResponseComp.OnHit.Broadcast(FGravityWhipThrowHitData(WhippableSettings.ThrownDamage, WhippableSettings.ThrownDamageType, ThrowingActor));
	}

	private bool ShouldDie(FMovementHitResult Hit)
	{
		if (ActiveDuration > WhippableSettings.MaxThrownDuration)
			return true;

		if (Owner.GetActorVelocity().Size() < 100.0)		
			return true;
		
		if (Hit.bBlockingHit)
		{
			UGravityWhipThrowResponseComponent ResponseComp = UGravityWhipThrowResponseComponent::Get(Hit.Actor);
			if(ResponseComp == nullptr || !ResponseComp.bNonThrowBlocking)
				return true;
		}

		return false;
	}
}