
class USummitStoneBeastCritterFlingDeathBehaviour : UBasicBehaviour
{
	UBasicAIHealthComponent HealthComp;
	UDragonSwordCombatResponseComponent SwordResponseComp;
	UBasicAICharacterMovementComponent MoveComp;
	UHazeActorRespawnableComponent RespawnComp;
	USummitStoneBeastCritterSettings Settings;

	AHazeCharacter Character;
	bool bHit;
	FVector ImpulseDirection;
	FRotator Rotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		SwordResponseComp = UDragonSwordCombatResponseComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		RespawnComp = UHazeActorRespawnableComponent::GetOrCreate(Owner);
		Settings = USummitStoneBeastCritterSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		SwordResponseComp.OnSimpleHit.AddUFunction(this,n"OnSwordHit");
		RespawnComp.OnRespawn.AddUFunction(this, n"Respawn");
	}

	UFUNCTION()
	private void Respawn()
	{
		bHit = false;
	}

	UFUNCTION()
	private void OnSwordHit(FDragonSwordHitDataSimple HitData)
	{
		if (HealthComp.IsDead())
			return;

		if(bHit)
			return;

		bHit = true;
	
		ImpulseDirection = HitData.HitDirection;
		USummitStoneBeastCritterEffectHandler::Trigger_OnDamage(Owner, FOnStoneCritterDamageParams(HitData.HitDirection));

		//DamageType is MeleeSharp for regularswings and Impact for jump slam attack
		if (HitData.DamageType == EDamageType::MeleeSharp)
		{
			Die();
			return;
		}

		if (Settings.FlingDeathRate != ESummitStoneBeastCritterFlingDeath::AlwaysFling)
		{
			if (Settings.FlingDeathRate == ESummitStoneBeastCritterFlingDeath::SometimesFling)
			{
				// Assumes ID to be the same on control and remote.
				UBasicAIVoiceOverComponent VOComp = UBasicAIVoiceOverComponent::Get(Owner);
				if (VOComp.VoiceOverID % 2 == 0)
					return; // fling
			}
			Die(); // instant death
		}
	}

	void Die()
	{
		if (HealthComp.IsDead())
			return;

		// Ensures that control side will die first and set target to nullptr before remote to prevent any behaviours on remote to run OnActivated with a nullptr target.
		if (!HasControl())
			return;
		
		// One hit kill
		CrumbDie();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDie()
	{
		HealthComp.DieLocal();
		HealthComp.OnDie.Broadcast(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)		
			return false;
		if(!bHit)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		UMovementGravitySettings::SetGravityScale(Owner, Settings.FlingDeathGravity, this);
		MoveComp.AddPendingImpulse((ImpulseDirection + FVector::UpVector) * Settings.FlingDeathImpactForce);
		Rotation = Math::RandomRotator(true).GetNormalized();
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);
		Character.MeshOffsetComponent.RelativeRotation = FRotator::ZeroRotator;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Character.MeshOffsetComponent.AddLocalRotation(Rotation * Settings.FlingDeathRotationSpeed * DeltaTime);

		if(ActiveDuration > 0.25 && (MoveComp.HasAnyValidBlockingImpacts() || MoveComp.IsOnAnyGround()))
		{
			Die();
			DeactivateBehaviour();
		}

		if(ActiveDuration > 5)
		{
			Die();
			DeactivateBehaviour();
		}
	}
}