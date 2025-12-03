event void FEnforcerDamageComponentOnBladeDamageSignature(float Damage, EDamageType DamageType, AHazeActor Instigator);
event void FEnforcerDamageComponentOnWhipHitDamageSignature(float Damage, EDamageType DamageType, AHazeActor Instigator);

class UEnforcerDamageComponent : UActorComponent
{
	FEnforcerDamageComponentOnBladeDamageSignature OnBladeDamage;
	FEnforcerDamageComponentOnWhipHitDamageSignature OnWhipHitDamage;

	UGravityBladeCombatResponseComponent BladeResponse;
	UGravityWhipImpactResponseComponent WhipResponse;
	UGravityWhipResponseComponent WhipGrabResponse;
	UHazeMovementComponent MoveComp;
	UBasicAIHealthComponent HealthComp;	
	UGravityWhippableComponent WhippableComp;
	UBasicAIAnimationComponent AnimComp;
	USkylineEnforcerSettings EnforcerSettings;

	FVector PushDirection = FVector::ZeroVector;

	EAnimHitPitch HitPitch = EAnimHitPitch::Center;

	EHazeCardinalDirection HitDirection = EHazeCardinalDirection::Forward;

	FVector PushHitDirection = FVector::ZeroVector;

	bool bTakeDamageFromWhipThrow = true;
	TInstigated<bool> bInvulnerable;
	bool bIgnoreBladeHitDamage = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		WhipResponse = UGravityWhipImpactResponseComponent::GetOrCreate(Owner);
		WhipResponse.OnImpact.AddUFunction(this, n"OnImpact");
		WhipResponse.OnRadialImpact.AddUFunction(this, n"OnRadialImpact");
		BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");	
		EnforcerSettings = USkylineEnforcerSettings::GetSettings(Cast<AHazeActor>(Owner));	
		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);

		UGravityWhipThrowResponseComponent ThrowResponseComp = UGravityWhipThrowResponseComponent::Get(Owner);
		if (ThrowResponseComp != nullptr)
			ThrowResponseComp.OnHit.AddUFunction(this, n"OnThrowHit");

		UEnforcerRocketLauncherResponseComponent RocketLauncherResponseComp = UEnforcerRocketLauncherResponseComponent::GetOrCreate(Owner);
		if (RocketLauncherResponseComp != nullptr)
			RocketLauncherResponseComp.OnHit.AddUFunction(this, n"OnRocketHit");

		WhipGrabResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		WhipGrabResponse.OnHitByWhip.AddUFunction(this, n"OnHitByWhip");
	}

	UFUNCTION()
	private void OnRocketHit(float Damage, EDamageType DamageType, AHazeActor Instigator)
	{
		if (bInvulnerable.Get())
			return;

		UBasicAIHealthComponent NPCHealthComp = UBasicAIHealthComponent::Get(Owner);
		if (NPCHealthComp != nullptr)
			NPCHealthComp.TakeDamage(Damage, DamageType, Instigator);
		// DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor::White);
	}

	UFUNCTION()
	private void OnThrowHit(FGravityWhipThrowHitData Data)
	{
		if (bInvulnerable.Get())
			return;

		if (!bTakeDamageFromWhipThrow)
			return;

		HealthComp.TakeDamage(Data.Damage, Data.DamageType, Data.Instigator);
		// DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor::White);

		auto HitStopComp = UCombatHitStopComponent::GetOrCreate(Owner);
		HitStopComp.ApplyHitStop(n"WhipImpact", 0.05);
	}

	UFUNCTION()
	private void OnRadialImpact(FGravityWhipRadialImpactData ImpactData)
	{
		if (bInvulnerable.Get())
			return;
		
		HealthComp.TakeDamage(ImpactData.Damage, EDamageType::Default, nullptr);
		// DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor::White);
	}

	UFUNCTION()
	protected void OnImpact(FGravityWhipImpactData ImpactData)
	{
		if (bInvulnerable.Get())
			return;
		if (bIgnoreBladeHitDamage)
			return;

		HealthComp.TakeDamage(ImpactData.Damage, EDamageType::Default, nullptr);
		// DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor::White);
	}

	UFUNCTION()
	protected void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{	
		if(bInvulnerable.Get())
		{
			FVector Direction = ((CombatComp.Owner.ActorLocation - Owner.ActorLocation).GetSafeNormal2D() + FVector(0, 0, 0.5)).GetNormalizedWithFallback(-CombatComp.Owner.ActorForwardVector);
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CombatComp.Owner);

			FStumble Stumble;
			Stumble.Move = Direction * 400;
			Stumble.Duration = 0.5;
			Player.ApplyStumble(Stumble);
			
			auto Data = FEnforcerEffectOnBladeResistData();
			Data.ImpactWorldLocation = HitData.ImpactPoint;
			UEnforcerEffectHandler::Trigger_OnBladeResist(Cast<AHazeActor>(Owner), Data);
			return;
		}

		AHazeActor Attacker = Cast<AHazeActor>(CombatComp.Owner);

		FVector Direction = (Owner.ActorLocation - CombatComp.Owner.ActorLocation).GetSafeNormal();
		MoveComp.AddPendingImpulse(Direction * (HitData.AttackMovementLength * 0.2));

		if (!bIgnoreBladeHitDamage)
		{
			// Damage is not handled elsewhere
			float Damage = HitData.Damage;
			if(WhippableComp.bGrabbed)
				Damage *= EnforcerSettings.MeleeAttackDamageWhipGrabbedMultiplier;
			HealthComp.TakeDamage(Damage, HitData.DamageType, Attacker);	
			OnBladeDamage.Broadcast(Damage, HitData.DamageType, Attacker);
		}
		
		PushHitDirection = FVector::ZeroVector;
		switch (CombatComp.HitDirection)
		{
			case EHazeCardinalDirection::Forward : 
			{
				PushHitDirection = Attacker.ActorForwardVector;
				break;
			}
			case EHazeCardinalDirection::Backward :
			{
				PushHitDirection = -Attacker.ActorForwardVector;
				break;
			}
			case EHazeCardinalDirection::Right :
			{
				PushHitDirection = -Attacker.ActorRightVector * 0.4;
				break;
			}
			case EHazeCardinalDirection::Left :
			{
				PushHitDirection = Attacker.ActorRightVector * 0.25;
				break;
			}
		}
		
		FVector AwayDirection = (Owner.ActorLocation - Attacker.ActorLocation).GetSafeNormal();

		FVector CombinedHitDirection = Math::Lerp(AwayDirection, PushHitDirection, 0.75);

		AHazePlayerCharacter PlayerAttacker = Cast<AHazePlayerCharacter>(Attacker);
		if (PlayerAttacker != nullptr) 
		{
			float ViewDot = Direction.DotProduct(PlayerAttacker.ViewRotation.Vector());
			float ViewAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.9, 0), FVector2D(0, 1), Math::Abs(ViewDot));
			CombinedHitDirection = Math::Lerp(CombinedHitDirection, PlayerAttacker.ViewRotation.Vector(), ViewAlpha);
		}
		PushDirection = CombinedHitDirection * HitData.AttackMovementLength * EnforcerSettings.GravityBladeHitMoveFraction;

		HitPitch = CombatComp.HitPitch;

		HitDirection = CombatComp.HitDirection;

		FEnforcerEffectOnBladeHitData EffectData;
		AHazeCharacter OwnerChar = Cast<AHazeCharacter>(Owner);
		float Dummy;
		Math::ProjectPositionOnLineSegment(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorUpVector * OwnerChar.CapsuleComponent.GetScaledCapsuleHalfHeight() * 2.0, HitData.ImpactPoint, EffectData.ImpactWorldLocation, Dummy);
		EffectData.BloodSpurtWorldDirection = PushHitDirection.GetSafeNormal();
		switch (CombatComp.HitPitch)
		{
			case EAnimHitPitch::Up :
			{
				EffectData.BloodSpurtWorldDirection -= Attacker.ActorUpVector;
				break;
			}
			case EAnimHitPitch::Down :
			{
				EffectData.BloodSpurtWorldDirection += Attacker.ActorUpVector;
				break;
			}
			case EAnimHitPitch::Center:
				break;
		}

		EffectData.BloodSpurtWorldDirection = EffectData.BloodSpurtWorldDirection.GetSafeNormal();
		EffectData.ImpactLocalLocation = Owner.ActorTransform.InverseTransformPosition(EffectData.ImpactWorldLocation);
		EffectData.BloodSpurtLocalDirection = Owner.ActorTransform.InverseTransformVectorNoScale(EffectData.BloodSpurtWorldDirection);

		UEnforcerEffectHandler::Trigger_OnBladeHit(Cast<AHazeActor>(Owner), EffectData);

		//Debug::DrawDebugLine(EffectData.ImpactWorldLocation, EffectData.ImpactWorldLocation + EffectData.BloodSpurtWorldDirection * 500, FLinearColor::Red, 5.0, 5.0);
	}
	
	UFUNCTION()
	private void OnHitByWhip(UGravityWhipUserComponent UserComponent, EHazeCardinalDirection InHitDirection,
	                         EAnimHitPitch InHitPitch, float HitWindowExtraPushback,
	                         float HitWindowPushbackMultiplier)
	{
		if(bInvulnerable.Get())
		{
			FVector Direction = ((UserComponent.Owner.ActorLocation - Owner.ActorLocation).GetSafeNormal2D() + FVector(0, 0, 0.5)).GetSafeNormal();
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(UserComponent.Owner);

			FStumble Stumble;
			Stumble.Move = Direction * 400;
			Stumble.Duration = 0.5;
			Player.ApplyStumble(Stumble);
			
			auto Data = FEnforcerEffectOnBladeResistData();
			Data.ImpactWorldLocation = Owner.ActorLocation;
			UEnforcerEffectHandler::Trigger_OnBladeResist(Cast<AHazeActor>(Owner), Data);
			return;
		}

		// DamageFlash::DamageFlashActor(Owner, 0.1, FLinearColor::White);

		AHazeActor Attacker = Cast<AHazeActor>(UserComponent.Owner);

		FVector Direction = (Owner.ActorLocation - UserComponent.Owner.ActorLocation).GetSafeNormal().RotateAngleAxis(Math::RandRange(-70, 70), FVector::UpVector);
		float Distance = (GravityWhip::Hit::HitBasePushback * HitWindowPushbackMultiplier + HitWindowExtraPushback);
		FVector Pushback = Direction * Distance;

		FVector NavLoc;
		if(Pathfinding::FindNavmeshLocation(Owner.ActorLocation + Pushback, 0, 500, NavLoc))
			MoveComp.AddPendingImpulse(Pushback);

		float Damage = 0.25;
		HealthComp.TakeDamage(Damage, EDamageType::Default, Attacker);	
		OnWhipHitDamage.Broadcast(Damage, EDamageType::Default, Attacker);

		HitPitch = InHitPitch;
		HitDirection = InHitDirection;
		PushDirection = Direction;

		PushHitDirection = FVector::ZeroVector;
		switch (InHitDirection)
		{
			case EHazeCardinalDirection::Forward : 
			{
				PushHitDirection = Attacker.ActorForwardVector;
				break;
			}
			case EHazeCardinalDirection::Backward :
			{
				PushHitDirection = -Attacker.ActorForwardVector;
				break;
			}
			case EHazeCardinalDirection::Right :
			{
				PushHitDirection = -Attacker.ActorRightVector * 0.4;
				break;
			}
			case EHazeCardinalDirection::Left :
			{
				PushHitDirection = Attacker.ActorRightVector * 0.25;
				break;
			}
		}
	}
}