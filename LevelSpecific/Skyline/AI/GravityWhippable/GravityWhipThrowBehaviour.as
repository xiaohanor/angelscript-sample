class UGravityWhipThrowBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

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
	USkylineEnforcerSentencedComponent SentencedComp;
	URagdollComponent RagdollComp;
	USkylineEnforcerDeathComponent DeathComp;

	UGravityBladeCombatTargetComponent BladeTargetComp; 
	UBasicAIHomingProjectileComponent HomingProjectileComp;

	FVector ThrowImpulse;
	AHazeActor ThrowingActor;
	FName PreviousCollisionProfile;
	ECollisionResponse PreviousCollisionResponse;
	float ThrowTime;
	FVector PreviousCenterLocation;
	float HitBouncedAngle;

	UHazeCapsuleCollisionComponent CapsuleComponent;
	FVector CapsuleComponentInitialRelativeLocation;

	TArray<AActor> HitTargets;

	AHazeCharacter Character;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AHazeCharacter>(Owner);
		SentencedComp = USkylineEnforcerSentencedComponent::GetOrCreate(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::GetOrCreate(Owner);
		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);						
		WhipTargetComp = UGravityWhipTargetComponent::Get(Owner);
		WhipSlingAutoAimComp = UGravityWhipSlingAutoAimComponent::Get(Owner);
		BladeTargetComp = UGravityBladeCombatTargetComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		HomingProjectileComp = UBasicAIHomingProjectileComponent::GetOrCreate(Owner);
		WhippableSettings = UGravityWhippableSettings::GetSettings(Owner);
		RagdollComp = URagdollComponent::GetOrCreate(Owner);
		DeathComp = USkylineEnforcerDeathComponent::GetOrCreate(Owner);

		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");

		CapsuleComponent = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		CapsuleComponentInitialRelativeLocation = CapsuleComponent.RelativeLocation;

		RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		HealthBarComp.SetHealthBarEnabled(true);
		DeathComp.RagdollForce.Reset();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnThrown(UGravityWhipUserComponent UserComponent,
		UGravityWhipTargetComponent TargetComponent,
		FHitResult HitResult, FVector Impulse)
	{
		if(IsBlockedByTag(SkylineAICapabilityTags::GravityWhippable))
			return;

		ThrowTime = Time::GetGameTimeSeconds();
		WhippableComp.bThrown = true;
		WhippableComp.OnThrown.Broadcast();
		ThrowingActor = Cast<AHazeActor>(UserComponent.Owner);
		
		UTargetableComponent PrimaryTarget = UPlayerTargetablesComponent::GetOrCreate(UserComponent.Owner).GetPrimaryTargetForCategory(GravityWhip::Grab::SlingTargetableCategory);
		if(PrimaryTarget != nullptr && PrimaryTarget.Owner != Owner)
		{
			AHazeActor TargetOwner = Cast<AHazeActor>(PrimaryTarget.Owner);
			if (TargetOwner != nullptr)
			{
				HomingProjectileComp.Target = TargetOwner;
				ThrowImpulse = (TargetOwner.FocusLocation - Owner.ActorCenterLocation).GetSafeNormal() * Impulse.Size();
			}
			else
				ThrowImpulse = Impulse;
		}
		else
		{
			ThrowImpulse = Impulse;
		}
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
	
		UBasicAIMovementSettings::SetAirFriction(Owner, 0, this);
		UBasicAIMovementSettings::SetGroundFriction(Owner, 0, this);
		UMovementGravitySettings::SetGravityScale(Owner, 0, this);

		// Set collision
		CapsuleComponent.ApplyCollisionProfile(CollisionProfile::IgnorePlayerCharacter, this);

		UEnforcerEffectHandler::Trigger_OnGravityWhipThrown(Owner);

		PreviousCenterLocation = Character.Mesh.GetSocketLocation(n"Hips");
		HitTargets.Empty();
		HealthBarComp.SetHealthBarEnabled(false);
		HitBouncedAngle = Math::RandRange(-5, 5);
		SentencedComp.PassiveSentence();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ThrowImpulse = FVector::ZeroVector;
		WhippableComp.bThrown = false;
		Owner.UnblockCapabilities(n"CrowdRepulsion", this);
		Owner.ClearSettingsByInstigator(this);

		// Never survive being thrown
		if(HealthComp.IsAlive())
			HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, ThrowingActor);

		WhipTargetComp.Enable(this);
		if (WhipSlingAutoAimComp != nullptr)
			WhipSlingAutoAimComp.Enable(this);

		HomingProjectileComp.Target = nullptr;
		ThrowTime = 0;

		// Restore collision
		CapsuleComponent.ClearCollisionProfile(this);

		Character.MeshOffsetComponent.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhipThrown, SubTagAIGravityWhipThrown::Thrown, EBasicBehaviourPriority::Medium, this);

		if(HomingProjectileComp.Target != nullptr)
		{
			FVector TargetLocation = HomingProjectileComp.Target.ActorCenterLocation;
			if(Owner.ActorVelocity.DotProduct(TargetLocation - Owner.ActorLocation) > 0)
			{
				float LaunchDuration = Time::GetGameTimeSince(ThrowTime);
				Owner.ActorVelocity += HomingProjectileComp.GetPlanarHomingAcceleration(TargetLocation, Owner.ActorVelocity.GetSafeNormal(), 300.0 * LaunchDuration) * DeltaTime;
			}
		}

		FHitResult Hit;
		if(!MoveComp.GetFirstValidImpact(Hit))
			return;

		if(Hit.bBlockingHit)
		{
			if(WhippableSettings.bEnableThrownDamage)
			{
				TArray<AActor> Targets;
				if(!HitTargets.Contains(Hit.Actor))
					Targets.AddUnique(Hit.Actor);

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

				bool bHitAnyTargets = false;
				for(AActor Target: Targets)
				{
					UGravityWhipThrowResponseComponent ResponseComp = UGravityWhipThrowResponseComponent::Get(Target);
					UGravityWhipImpactResponseComponent ImpactComp = UGravityWhipImpactResponseComponent::Get(Target);
					if(ResponseComp == nullptr && ImpactComp == nullptr)
						continue;

					HitTargets.Add(Target);
					if(HasControl())
					{
						FGravityWhipImpactData ImpactData;
						if(ImpactComp != nullptr)
						{
							ImpactData.ImpactVelocity = Owner.ActorCenterLocation - PreviousCenterLocation;
							ImpactData.HitResult = Hit;
							ImpactData.Damage = WhippableSettings.ThrownDamage;
							ImpactData.ThrownActor = Owner;
						}
						CrumbHit(ThrowingActor, Hit, ResponseComp, ImpactComp, ImpactData);
					}
					bHitAnyTargets = true;
				}

				if(bHitAnyTargets)
				{
					FVector Force = Owner.ActorVelocity * 5;
					if(HasControl())
						CrumbRagdoll(Force);
					Ragdoll(Force);
					
					FEnforcerEffectOnGravityWhipThrowImpactData Data;
					Data.ImpactLocation = Hit.Location;
					Data.ImpactNormal = Hit.Normal;
					UEnforcerEffectHandler::Trigger_OnGravityWhipThrowImpact(Owner, Data);
					
					HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, ThrowingActor);
					DeactivateBehaviour();
				}

				if (Targets.Num() != 0)
				{
					auto HitStopComp = UCombatHitStopComponent::GetOrCreate(Owner);
					HitStopComp.ApplyHitStop(n"WhipImpact", 0.05);
				}

				// This should instead try to use the remote side hit location and only use a crumbed location as a backup in OnDeactived. But meh.
				if(!bHitAnyTargets && HasControl())
					CrumbEffects(Hit);
			}
		}

		if(ShouldDie(Hit))
		{
			// AlwaysRagdoll when thrown
			FVector Force = Owner.ActorVelocity;
			if(HasControl())
				CrumbRagdoll(Force);
			Ragdoll(Force);

			HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, ThrowingActor);
			DeactivateBehaviour();

			if (Hit.bBlockingHit)
			{
				FEnforcerEffectOnGravityWhipThrowImpactData Data;
				Data.ImpactLocation = Hit.Location;
				Data.ImpactNormal = Hit.Normal;
				UEnforcerEffectHandler::Trigger_OnGravityWhipThrowImpact(Owner, Data);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbRagdoll(FVector Force)
	{
		DeathComp.RagdollForce.Set(Force);
	}

	private void Ragdoll(FVector Force)
	{
		if (!RagdollComp.bIsRagdolling)
		{
			RagdollComp.ApplyRagdoll(Character.Mesh, Character.CapsuleComponent);
			RagdollComp.ApplyRagdollImpulse(Character.Mesh, FRagdollImpulse(ERagdollImpulseType::WorldSpace, Force, Character.Mesh.GetSocketLocation(n"Spine2"), n"Spine2"));
			UEnforcerEffectHandler::Trigger_OnRagdoll(Owner);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbEffects(FHitResult Hit)
	{
		Effects(Hit);
	}

	private void Effects(FHitResult Hit)
	{
		ForceFeedback::PlayWorldForceFeedback(ForceFeedback::Default_Light, Hit.ImpactPoint, false, this, 150, 400);
		if(WhippableComp.ImpactCameraShake != nullptr)
		{
			for(AHazePlayerCharacter Player : Game::Players)
				Player.PlayWorldCameraShake(WhippableComp.ImpactCameraShake, this, Hit.ImpactPoint, 150, 400);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHit(AHazeActor Thrower,  FHitResult Hit, UGravityWhipThrowResponseComponent ResponseComp, UGravityWhipImpactResponseComponent ImpactComp, FGravityWhipImpactData ImpactData)
	{
		if(ResponseComp != nullptr)
			ResponseComp.OnHit.Broadcast(FGravityWhipThrowHitData(WhippableSettings.ThrownDamage, WhippableSettings.ThrownDamageType, Thrower));
		else if(ImpactComp != nullptr)
			ImpactComp.Impact(ImpactData);

		Effects(Hit);
	}

	private bool ShouldDie(FHitResult Hit)
	{
		// I have seen c-beams glittering near the tannhäuser gate...
		if (ActiveDuration > WhippableSettings.MaxThrownDuration)
			return true;

		bool bDieAtLowVelocity = (WhippableSettings.DeathType == EGravityWhippableDeathType::Velocity) || (WhippableSettings.DeathType == EGravityWhippableDeathType::VelocityAndImpact);
		if (bDieAtLowVelocity && (Owner.GetActorVelocity().Size() < 100.0)) 		
			return true;
		
		bool bDieFromImpact = (WhippableSettings.DeathType == EGravityWhippableDeathType::Impact) || (WhippableSettings.DeathType == EGravityWhippableDeathType::VelocityAndImpact);
		if (bDieFromImpact && Hit.bBlockingHit)
		{
			UGravityWhipThrowResponseComponent ResponseComp = UGravityWhipThrowResponseComponent::Get(Hit.Actor);
			if(ResponseComp == nullptr || !ResponseComp.bNonThrowBlocking)
				return true;
		}

		return false;
	}
}