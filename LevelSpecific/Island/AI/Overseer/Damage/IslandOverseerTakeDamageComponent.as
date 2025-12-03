event void FIslandOverseerTakeDamageComponentImpactEvent(bool bAddTint);

class UIslandOverseerTakeDamageComponent : UActorComponent
{
	AAIIslandOverseer Overseer;
	UBasicAIHealthComponent HealthComp;
	UIslandOverseerSettings Settings;
	UIslandOverseerVisorComponent VisorComp;

	FIslandOverseerTakeDamageComponentImpactEvent OnImpact;

	bool bHitReactionTakeDamageLeft;
	bool bHitReactionTakeDamageRight;
	bool bHitReactionTakeDamageProfile;
	bool bHitReactionTakeDamageCutHead;
	bool bHitReactionTakeDamageCutHeadDead;
	bool bHitReactionMoveLeft;
	bool bHitReactionMoveRight;
	bool bBlockReactions;
	float CutHeadStartHealth;
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Overseer = Cast<AAIIslandOverseer>(Owner);
		Settings = UIslandOverseerSettings::GetSettings(Overseer);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		Overseer.DamageResponseComp.OnImpactEvent.AddUFunction(this, n"Impact");
		UIslandOverseerRedBlueDamageComponent::GetOrCreate(Owner).OnDamage.AddUFunction(this, n"Damage");

		Overseer.OnDoorCutHeadPhaseStart.AddUFunction(this, n"CutHeadStart");

		AIslandOverseerTowardsChaseMoveSplineContainer Container = TListedActors<AIslandOverseerTowardsChaseMoveSplineContainer>()[0];
		TArray<AActor> Actors;
		Container.GetAttachedActors(Actors);
		Spline = Cast<ASplineActor>(Actors[0]).Spline;
	}

	UFUNCTION()
	private void CutHeadStart()
	{
		CutHeadStartHealth = HealthComp.CurrentHealth;
	}

	private bool CanDamage()
	{
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::Dead)
			return false;
		if(HealthComp.IsDead())
			return false;
		// if(!VisorComp.bOpen)
		// 	return false;
		// if(VisorComp.bClosing)
		// 	return false;
		return true;
	}

	UFUNCTION()
	private void Damage(float DamageTime, AHazeActor Instigator)
	{
		if(!CanDamage())
			return;

		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::IntroCombat)
			HealthComp.TakeDamage(DamageTime * Settings.IntroCombatRedBlueDamagePerSecond, EDamageType::Projectile, Instigator);
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::TowardsChase)
			HealthComp.TakeDamage(DamageTime * Settings.ChaseRedBlueDamagePerSecond, EDamageType::Projectile, Instigator);
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::SideChase)
			HealthComp.TakeDamage(DamageTime * Settings.ChaseRedBlueDamagePerSecond, EDamageType::Projectile, Instigator);	
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::Door)
			HealthComp.TakeDamage(DamageTime * Settings.DoorRedBlueDamagePerSecond, EDamageType::Projectile, Instigator);	
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::DoorCutHead)
		{
			float CutHeadDamage = DamageTime * Settings.DoorCutHeadRedBlueDamagePerSecond * CutHeadStartHealth;
			HealthComp.TakeDamage(CutHeadDamage, EDamageType::Projectile, Instigator);	
		}
	}

	UFUNCTION()
	private void Impact(FIslandRedBlueImpactResponseParams Data)
	{
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::Dead)
			return;
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::Flood)
			return;
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::Idle)
			return;
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::PovCombat)
			return;

		if(!bBlockReactions)
		{
			if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::SideChase)
				bHitReactionTakeDamageProfile = true;
			else if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::DoorCutHead)
			{
				if(Overseer.HealthComp.IsDead())
					bHitReactionTakeDamageCutHeadDead = true;
				else	
					bHitReactionTakeDamageCutHead = true;
			}
			else
			{
				bool bRight = Owner.ActorRightVector.DotProduct(Data.ImpactLocation - Owner.ActorLocation) > 0;
				bHitReactionTakeDamageRight = bRight;
				bHitReactionTakeDamageLeft = !bRight;
			}
		}
		
		OnImpact.Broadcast(!Overseer.HealthComp.IsDead());
		UIslandOverseerEventHandler::Trigger_OnHeadTakeDamage(Overseer);
		UIslandOverseerEventHandler::Trigger_OnRedBlueHit(Overseer, FIslandOverseerEventHandlerOnRedBlueHitData(HealthComp.IsDead(), Data.ImpactLocation, Data.ImpactNormal));
	}

	void TakeGeneralDamage(float Damage, FIslandRedBlueImpactResponseParams Data)
	{
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::Dead)
			return;
		if(HealthComp.IsDead())
			return;

		bool bRight = Owner.ActorRightVector.DotProduct(Data.ImpactLocation - Owner.ActorLocation) > 0;
		bHitReactionTakeDamageRight = bRight;
		bHitReactionTakeDamageLeft = !bRight;

		HealthComp.TakeDamage(Damage, EDamageType::Default, Data.Player);
		OnImpact.Broadcast(!HealthComp.IsDead());
	}

	void Crush(FVector ImpactLocation)
	{
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::Dead)
			return;

		FVector SplineLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(ImpactLocation);
		bool bRight = Owner.ActorRightVector.DotProduct(ImpactLocation - SplineLocation) > 0;
		bHitReactionMoveRight = bRight;
		bHitReactionMoveLeft = !bRight;
	}

	void ResetMoveDamage()
	{
		bHitReactionMoveRight = false;
		bHitReactionMoveLeft = false;
	}
}