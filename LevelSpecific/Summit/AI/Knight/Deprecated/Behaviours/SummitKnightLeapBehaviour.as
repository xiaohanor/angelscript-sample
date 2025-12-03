struct FSummitKnightLeapParams
{
	FVector LeapToLoc;
}

class USummitKnightLeapBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitCameraShakeComponent CamerShakeComp; 
	USummitMeltComponent MeltComp; 
	USummitKnightSwordComponent WeaponComp;

	USummitKnightDeprecatedSettings KnightSettings;
	FBasicAIAnimationActionDurations Durations;

	TArray<AHazeActor> HitTargets;
	FVector LeapToLocation;
	FVector LeapToDirection;
	float LeapDistance;

	bool bLanded;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		CamerShakeComp = USummitCameraShakeComponent::GetOrCreate(Owner);
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
		KnightSettings = USummitKnightDeprecatedSettings::GetSettings(Owner);
		WeaponComp = USummitKnightSwordComponent::Get(Owner);

		Durations.Telegraph = KnightSettings.LeapTelegraphDuration;
		Durations.Anticipation = KnightSettings.LeapAnticipationDuration;
		Durations.Action = KnightSettings.LeapAttackDuration;
		Durations.Recovery = KnightSettings.LeapRecoveryDuration;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TargetComp.GetDistanceToTarget() > KnightSettings.LeapMaxRange)
			return false;
		if (TargetComp.GetDistanceToTarget() < KnightSettings.LeapMinRange)
			return false;
		if (MeltComp.bMelted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;		
		if(!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(KnightSettings.LeapGentlemanCost))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())
			return true;
		if (MeltComp.bMelted)
			return true;
		
		return false;
	}

	//Might be an issue if player is not grounded (like the acid player)
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, KnightSettings.LeapGentlemanCost);
		LeapToLocation = TargetComp.Target.ActorLocation;
		LeapToDirection = (LeapToLocation - Owner.ActorLocation).GetSafeNormal();
		LeapDistance = Owner.ActorLocation.Distance(LeapToLocation);
		HitTargets.Empty();
				
		bLanded = false;

		//AnimComp.RequestAction(FeatureTagSummitRubyKnight::Attacks, SubTagSummitRubyKnightAttack::SwordAttackLeap, EBasicBehaviourPriority::Medium, this, Durations);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, KnightSettings.LeapTokenCooldown);
		Cooldown.Set(KnightSettings.LeapCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(LeapToLocation + LeapToDirection * 1000);

		if (Durations.IsInTelegraphRange(ActiveDuration) || Durations.IsInAnticipationRange(ActiveDuration))
			return;

		if(Durations.IsInActionRange(ActiveDuration))
		{
			DestinationComp.MoveTowards(LeapToLocation, KnightSettings.LeapMoveSpeed * (LeapDistance * 0.0005));

			for(AHazePlayerCharacter Player: Game::Players)
			{
				FCollisionShape SwordShape;
				SwordShape.SetCapsule(90, 350);
				FTransform SwordTransform = WeaponComp.WorldTransform;
				SwordTransform.SetRotation(SwordTransform.TransformRotation(FRotator(0, 0, -90).Quaternion()));
				SwordTransform.AddToTranslation(SwordTransform.Rotation.UpVector * 350);
				UHazeCapsuleCollisionComponent Collision = Player.CapsuleComponent;
				if(Overlap::QueryShapeOverlap(SwordShape, SwordTransform, Collision.GetCollisionShape(), Collision.WorldTransform))
					CrumbHitTarget(Player);							
			}
		}
		
		if (!bLanded && Durations.IsInRecoveryRange(ActiveDuration+0.2))
		{
			bLanded = true;


			for(AHazePlayerCharacter Player: Game::Players)
			{
				if(Player.ActorLocation.Distance(WeaponComp.WorldLocation) < 800)
					CrumbHitTarget(Player);
			}
		}		
	}

	UFUNCTION(CrumbFunction)
	void CrumbHitTarget(AHazeActor Target)
	{		
		if(HitTargets.Contains(Target))
			return;

		HitTargets.Add(Target);
		
		auto DragonComp = UPlayerTeenDragonComponent::Get(Target);
		FVector Dir = (Target.ActorLocation - Owner.ActorLocation).ConstrainToPlane(Target.ActorUpVector).GetSafeNormal2D();
		FTeenDragonStumble Stumble;
		Stumble.Duration = 1;
		Stumble.Move = Dir * 2000;
		Stumble.Apply(Target);
		Target.SetActorRotation((-Stumble.Move).ToOrientationQuat());
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Target);
		if(Player != nullptr)
			Player.PlayCameraShake(CamerShakeComp.CameraShake, this);

		auto PlayerHealthComp = UPlayerHealthComponent::Get(Target);
		if(PlayerHealthComp != nullptr)
			PlayerHealthComp.DamagePlayer(0.5, nullptr, nullptr);
	}
}