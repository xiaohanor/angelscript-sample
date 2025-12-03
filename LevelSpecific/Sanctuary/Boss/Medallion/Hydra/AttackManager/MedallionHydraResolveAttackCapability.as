struct FSanctuaryMedallionHydraParams
{
	EMedallionHydra HydraType;
	AHazePlayerCharacter TargetPlayer;
	EMedallionHydraAttack Attack;
	float AttackDuration;
}

struct FSanctuaryMedallionHydraResolveAttackActionParams
{
	TArray<FSanctuaryMedallionHydraParams> HydraActions;
}

class USanctuaryMedallionHydraResolveAttackCapability : UHazeActionQueueCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	FSanctuaryMedallionHydraResolveAttackActionParams QueueParameters;

	ASanctuaryBossMedallionHydraReferences Refs;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryMedallionHydraResolveAttackActionParams Parameters)
	{
		if (Refs == nullptr)
			CacheRefs();

		QueueParameters = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for (auto HydraAction : QueueParameters.HydraActions)
		{
			for (auto Hydra : Refs.Hydras)
			{
				if (Hydra.bDead)
					continue;
				if (Hydra.HydraType == HydraAction.HydraType)
				{
					bool bAttacked = false;
					if (HydraAction.Attack == EMedallionHydraAttack::BasicProjectileSingle)
					{
						bAttacked = Hydra.LaunchProjectileSingle(HydraAction.TargetPlayer);
					}

					if (HydraAction.Attack == EMedallionHydraAttack::BasicProjectileTripple)
					{
						bAttacked = Hydra.LaunchProjectileTriple(HydraAction.TargetPlayer);
					}

					if (HydraAction.Attack == EMedallionHydraAttack::SplittingProjectile)
					{
						bAttacked = Hydra.LaunchSplittingProjectile2(HydraAction.TargetPlayer);
					}

					if (HydraAction.Attack == EMedallionHydraAttack::SplittingSetOffsetProjectile)
					{
						bAttacked = Hydra.LaunchSplittingProjectileSetOffset(HydraAction.TargetPlayer);
					}

					if (HydraAction.Attack == EMedallionHydraAttack::SplittingProjectileTriple)
					{
						bAttacked = Hydra.LaunchSplittingProjectileTriple(HydraAction.TargetPlayer);
					}

					if (HydraAction.Attack == EMedallionHydraAttack::SplittingProjectileQuad)
					{
						bAttacked = Hydra.LaunchSplittingProjectileQuad(HydraAction.TargetPlayer);
					}

					if (HydraAction.Attack == EMedallionHydraAttack::FlyingProjectile)
					{
						bAttacked = Hydra.LaunchProjectileFlyingSingle(HydraAction.TargetPlayer);
					}

					if (HydraAction.Attack == EMedallionHydraAttack::FlyingSlashLaser)
					{
						Hydra.FlyingSlashLaser(HydraAction.TargetPlayer);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::RainAttack)
					{
						Hydra.RainAttack(HydraAction.TargetPlayer);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::ArcSpray)
					{
						if (HydraAction.TargetPlayer == Game::Mio)
							Refs.MioArcSprayAttackActor.Activate(Hydra);
						else
							Refs.ZoeArcSprayAttackActor.Activate(Hydra);
						bAttacked = true;
					}
					
					if (HydraAction.Attack == EMedallionHydraAttack::ChaseLaser)
					{
						if (HydraAction.TargetPlayer == Game::Mio)
							Refs.MioChaseLaserAttackActor.Activate(Hydra);
						else
							Refs.ZoeChaseLaserAttackActor.Activate(Hydra);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::SlashLaser)
					{
						if (HydraAction.TargetPlayer == Game::Mio)
							Refs.MioSlashLaserAttackActor.Activate(Hydra);
						else
							Refs.ZoeSlashLaserAttackActor.Activate(Hydra);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::AboveProjectile)
					{
						if (HydraAction.TargetPlayer == Game::Mio)
							Refs.MioAboveProjectileAttackActor.Activate(Hydra);
						else
							Refs.ZoeAboveProjectileAttackActor.Activate(Hydra);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::SidescrollerSpam)
					{
						if (HydraAction.TargetPlayer == Game::Mio)
							Refs.MioSidescrollerSpamAttackActor.Activate(Hydra);
						else
							Refs.ZoeSidescrollerSpamAttackActor.Activate(Hydra);
						bAttacked = true;
					}

					//Ballista

					if (HydraAction.Attack == EMedallionHydraAttack::LaneLaser1)
					{
						Refs.BallistaLaneLaser1AttackActor.Activate(Hydra, HydraAction.AttackDuration);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::LaneLaser2)
					{
						Refs.BallistaLaneLaser2AttackActor.Activate(Hydra, HydraAction.AttackDuration);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::LaneLaser3)
					{
						Refs.BallistaLaneLaser3AttackActor.Activate(Hydra, HydraAction.AttackDuration);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::LaneLaserAbove1)
					{
						Refs.BallistaLaneLaserAboveAttackActor.Activate(Hydra, HydraAction.AttackDuration);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::LaneLaserAbove2)
					{
						Refs.BallistaLaneLaserAboveAttackActor2.Activate(Hydra, HydraAction.AttackDuration);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::LaneLaserAbove3)
					{
						Refs.BallistaLaneLaserAboveAttackActor3.Activate(Hydra, HydraAction.AttackDuration);
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::Wave)
					{
						Refs.WaveAttackActor.Activate();
						bAttacked = true;
					}

					if (HydraAction.Attack == EMedallionHydraAttack::BallistaProjectile)
					{
						bAttacked = Hydra.BallistaProjectiles(HydraAction.TargetPlayer);
					}

					if (HydraAction.Attack == EMedallionHydraAttack::Meteor)
					{
						Refs.MeteorAttackActor.Activate();
						bAttacked = true;
					}

					if (bAttacked)
						EventHandlerAttack(Hydra, HydraAction.Attack);
				}
			}
		}
	}

	void EventHandlerAttack(ASanctuaryBossMedallionHydra Hydra, EMedallionHydraAttack AttackType)
	{
		{
			FSanctuaryBossMedallionHydraEventAttackData Data;
			Data.AttackType = AttackType;
			USanctuaryBossMedallionHydraEventHandler::Trigger_OnAttackStarted(Hydra, Data);
		}
		{
			FSanctuaryBossMedallionManagerEventAttackData Data;
			Data.AttackType = AttackType;
			Data.Hydra = Hydra;
			UMedallionHydraAttackManagerEventHandler::Trigger_OnAttackStarted(Refs.HydraAttackManager, Data);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	private void CacheRefs()
	{
		TListedActors<ASanctuaryBossMedallionHydraReferences> ListedRefs;
		Refs = ListedRefs.Single;
	}
};