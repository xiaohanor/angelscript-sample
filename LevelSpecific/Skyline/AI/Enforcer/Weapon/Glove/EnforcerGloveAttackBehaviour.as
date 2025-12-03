class UEnforcerGloveAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	const FName WeaponTag = n"EnforcerWeaponGlove";
	default CapabilityTags.Add(WeaponTag);
	default CapabilityTags.Add(n"Attack");

	UEnforcerGloveSettings GloveSettings;
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UEnforcerGloveComponent Weapon;
	UBasicAIHealthComponent HealthComp;
	UBasicAICharacterMovementComponent MoveComp;

	private AHazeCharacter Character;
	private FVector TargetDirection;
	private AHazeActor Target;
	private bool bStoppedTelegraph;
	private FVector PreviousGloveLocation;
	private TArray<AHazePlayerCharacter> HitPlayers;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		Character = Cast<AHazeCharacter>(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		Weapon = UEnforcerGloveComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		if (Weapon == nullptr)
		{
			UBasicAIWeaponWielderComponent WielderComp = UBasicAIWeaponWielderComponent::Get(Owner);
			if (WielderComp != nullptr) 
			{
				if (WielderComp.Weapon != nullptr)
					Weapon = UEnforcerGloveComponent::Get(WielderComp.Weapon);
				WielderComp.OnWieldWeapon.AddUFunction(this, n"OnWieldWeapon");
			}
			if(Weapon == nullptr)
			{
				// You can't block yourself using yourself as instigator, will need to use a name
				Owner.BlockCapabilities(WeaponTag, FName(GetPathName()));
			}
		}

		GloveSettings = UEnforcerGloveSettings::GetSettings(Owner);

		AnimComp.bIsAiming = true;
	}

	UFUNCTION()
	private void OnWieldWeapon(ABasicAIWeapon WieldedWeapon)
	{
		if (WieldedWeapon == nullptr)
			return;
		UEnforcerGloveComponent NewWeapon = UEnforcerGloveComponent::Get(WieldedWeapon);
		if (NewWeapon != nullptr)
		{
			Weapon = NewWeapon;
			Weapon.SetWielder(Owner);
			if(Owner.IsCapabilityTagBlocked(WeaponTag))
				Owner.UnblockCapabilities(WeaponTag, FName(GetPathName()));
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Weapon == nullptr) 
			return;

		UBasicAITraversalSettings::SetChaseMinRange(Owner, 500, this, EHazeSettingsPriority::Script);

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
		if (Weapon == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.AttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, GloveSettings.MinimumAttackRange))
			return false;
		if (!TargetComp.HasVisibleTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this) && (GloveSettings.GentlemanCost != EGentlemanCost::None))
			return false;
		if(!GentCostComp.IsTokenAvailable(GloveSettings.GentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > GloveSettings.TelegraphDuration + GloveSettings.AttackDuration + GloveSettings.RecoveryDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		GentCostComp.ClaimToken(this, GloveSettings.GentlemanCost);
		UEnforcerWeaponEffectHandler::Trigger_OnTelegraph(Weapon.WeaponActor, FEnforcerWeaponEffectTelegraphData(Weapon.GetLaunchLocation(), GloveSettings.TelegraphDuration));
		Target = TargetComp.Target;
		TargetDirection = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::EnforcerGloveAttack, EBasicBehaviourPriority::Medium, this);
		HitPlayers.Empty();
		PreviousGloveLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, GloveSettings.AttackTokenCooldown);
		UEnforcerWeaponEffectHandler::Trigger_OnStopTelegraph(Weapon.WeaponActor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Owner.ActorLocation + TargetDirection * 500);

		if(ActiveDuration < GloveSettings.TelegraphDuration)
		{
			TargetDirection = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			return;
		}

		if(!bStoppedTelegraph)
		{
			bStoppedTelegraph = true;
			UEnforcerWeaponEffectHandler::Trigger_OnStopTelegraph(Weapon.WeaponActor);
		}

		if(ActiveDuration > GloveSettings.TelegraphDuration + GloveSettings.AttackDuration)
			return;

		if(ActiveDuration > GloveSettings.TelegraphDuration)
		{
			FVector GloveLocation = Character.Mesh.GetSocketLocation(n"RightHand");
			if(PreviousGloveLocation == FVector::ZeroVector)
			{
				PreviousGloveLocation = GloveLocation;
				return;
			}
			FVector Delta = PreviousGloveLocation - GloveLocation;
			PreviousGloveLocation = GloveLocation;

			FCollisionShape GloveShape;
			GloveShape.SetSphere(100);
			FTransform Transform;
			Transform.SetLocation(GloveLocation);
			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(HitPlayers.Contains(Player))
					continue;

				if(Overlap::QueryShapeSweep(GloveShape, Transform, Delta, Player.CapsuleComponent.GetCollisionShape(), Player.CapsuleComponent.WorldTransform))
				{
					HitPlayers.Add(Player);
					Player.DamagePlayerHealth(0.5);
				}
			}

			DestinationComp.MoveTowards(Owner.ActorLocation + TargetDirection * 500, 750);
		}
	}
}