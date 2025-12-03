struct FHoveringEnforcerDeathParams
{
	ASkylineJetpackCombatZone BillboardZone;
}

class UEnforcerHoveringBillboardDeathCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"Death");
	default CapabilityTags.Add(n"EnforcerDeath");
	default CapabilityTags.Add(n"BillboardCombat");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UBasicAIHealthComponent HealthComp;
	UBasicAIAnimationComponent AnimComp;
	UHazeActorRespawnableComponent RespawnComp;
	UTargetableOutlineComponent BladeOutline;
	UGravityWhipTargetComponent WhipTargetComp;
	UGravityWhipSlingAutoAimComponent WhipAutoAimComp;
	UHazeCharacterSkeletalMeshComponent Mesh;
	URagdollComponent RagdollComp;
	UHazeCapsuleCollisionComponent Collision;
	UEnforcerDangerZone DangerIndicator;
	UBasicAIDestinationComponent DestinationComp;
	UEnforcerHoveringComponent HoveringComp;
	ASkylineJetpackCombatZoneManager BillboardManager;
	ASkylineJetpackCombatZone BillboardZone;
	UEnforcerHoveringSettings Settings;

	float RemoteDeathTime = -1000.0;
	float DeathTime;
	bool bIsDying;
	bool bRemoteFinishedDying = false;
	float StumbleTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		BladeOutline = UTargetableOutlineComponent::Get(Owner);
		DestinationComp = UBasicAIDestinationComponent::Get(Owner);
		HoveringComp = UEnforcerHoveringComponent::GetOrCreate(Owner);
		DangerIndicator = UEnforcerDangerZone::Get(Owner);
		BillboardManager = TListedActors<ASkylineJetpackCombatZoneManager>().GetSingle();

		HealthComp.OnRemotePreDeath.AddUFunction(this, n"OnRemotePreDeath");
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		WhipTargetComp = UGravityWhipTargetComponent::Get(Owner);
		WhipAutoAimComp = UGravityWhipSlingAutoAimComponent::Get(Owner);

		Settings = UEnforcerHoveringSettings::GetSettings(Owner);

		AHazeCharacter CharOwner = Cast<AHazeCharacter>(Owner);
		Mesh = CharOwner.Mesh;
		Collision = CharOwner.CapsuleComponent;
		RagdollComp = URagdollComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoveringEnforcerDeathParams& OutParams) const
	{
		if (!HealthComp.IsDead())
			return false;
		if (bIsDying)
			return false;
		if (HoveringComp.TargetBillboardZone.Get() == nullptr)
		{
			// Player killed us after we completed recovery, reclaim a billboard zone to fall against
			OutParams.BillboardZone = BillboardManager.GetNearestUnoccupiedBillboardZone(Owner.ActorLocation);
		}
		else 
		{
			// Normal case, we're still stuck to or recovering from being stuck
			OutParams.BillboardZone = HoveringComp.TargetBillboardZone.Get();			
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > Settings.BillboardDeathDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHoveringEnforcerDeathParams Params)
	{
		BillboardZone = Params.BillboardZone;
		if ((HoveringComp.TargetBillboardZone.Get() != nullptr) && (HoveringComp.TargetBillboardZone.Get() != BillboardZone))
			HoveringComp.TargetBillboardZone.Get().CurrentlyOccupiedBy = nullptr;
		HoveringComp.TargetBillboardZone.Apply(BillboardZone, this, EInstigatePriority::High);

		StumbleTime = Settings.BillboardDeathStumbleAwayBeforeExplosionDelay;

		HealthComp.TriggerStartDying();
		if (!HasControl()) 
			HealthComp.RemoteDie();
		HealthComp.OnDie.Broadcast(Owner);
		DeathTime = Time::GetGameTimeSeconds();
		bIsDying = true;
		Owner.BlockCapabilities(BasicAITags::Behaviour, this);
		
		DangerIndicator.Show();
		FVector DangerLoc = Owner.ActorLocation + Owner.ActorUpVector * 100.0;
		DangerLoc = BillboardManager.LineBillboardPlaneIntersection(DangerLoc, -BillboardZone.ActorUpVector);
		DangerLoc += BillboardZone.ActorUpVector * 10.0;
		DangerIndicator.WorldLocation = DangerLoc; 
		DangerIndicator.AttachToComponent(BillboardZone.RootComponent, NAME_None, EAttachmentRule::KeepWorld);

		BladeOutline.BlockOutline(this);

		if (WhipTargetComp != nullptr)
			WhipTargetComp.Disable(Owner);
		if (WhipAutoAimComp != nullptr)
			WhipAutoAimComp.Disable(Owner);

		AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::GravityWhipWallImpact, SubTagAIGravityWhipWallImpact::Death, EBasicBehaviourPriority::Maximum, this);

		BillboardZone.TelegraphExplosion();

		UEnforcerJetpackEffectHandler::Trigger_OnTelegraphBillboardExplosion(Owner, FJetpackBillboardParams(BillboardZone));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{			
		// Take out the closest part of the billboard
		BillboardZone.Explode(-BillboardZone.ActorUpVector, 50000.0);

		// Stop occupying billboard zone
		BillboardZone.CurrentlyOccupiedBy = nullptr;
		HoveringComp.TargetBillboardZone.Clear(this);

		// Rock the billboard 
		if (BillboardManager.FauxPhysicsRoot != nullptr)
			FauxPhysics::ApplyFauxImpulseToActorAt(BillboardManager.FauxPhysicsRoot, Owner.ActorCenterLocation, -BillboardZone.ActorUpVector * Settings.BillboardZoneExplosionForce);

		Owner.AddActorDisable(this);
		RagdollComp.ClearRagdoll(Mesh, Collision);
		AnimComp.ClearFeature(this);
		DangerIndicator.Hide();
		
		if (bRemoteFinishedDying)
		{
			Owner.RemoveActorVisualsBlock(this);
			Owner.RemoveActorCollisionBlock(this);
		}

		if (WhipTargetComp != nullptr)
			WhipTargetComp.Enable(Owner);
		if (WhipAutoAimComp != nullptr)
			WhipAutoAimComp.Enable(Owner);

		UEnforcerJetpackEffectHandler::Trigger_OnExplodeAtBillboard(Owner, FJetpackBillboardParams(BillboardZone));
		UEnforcerEffectHandler::Trigger_OnUnspawn(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(RagdollComp.IsRagdollAllowed() && !RagdollComp.bIsRagdolling)
		{
			RagdollComp.ApplyRagdoll(Mesh, Collision);
			UEnforcerEffectHandler::Trigger_OnRagdoll(Owner);
		}

		if (!HasControl() && (ActiveDuration > Settings.BillboardDeathDuration))
		{
			// Remote side completes animation before crumb deactivation, turn off stuff
			bRemoteFinishedDying = true;
			Owner.AddActorVisualsBlock(this);
			Owner.AddActorCollisionBlock(this);
		}

		// In case we were hit in air we push down towards billboard
		FVector Dest = BillboardManager.LineBillboardPlaneIntersection(Owner.ActorLocation, -BillboardZone.ActorUpVector);
		if (!Dest.IsWithinDist(BillboardZone.ActorLocation, 300.0))
		{
			// Should be fairly uncommon, but fall more towards target zone center to avoid explosion looking very weird
			FVector BillboardCenter = BillboardManager.LineBillboardPlaneIntersection(BillboardZone.ActorLocation, -BillboardZone.ActorUpVector);
			Dest = BillboardCenter +  (Dest - BillboardCenter).GetSafeNormal() * 250.0;

		}
		DestinationComp.MoveTowardsIgnorePathfinding(Dest, Settings.BillBoardDeathFallSpeed);

		DangerIndicator.Update(DeltaTime);
		DangerIndicator.RelativeRotation = FRotator::ZeroRotator;

		if (ActiveDuration > StumbleTime)
		{
			StumbleTime = BIG_NUMBER;
			if ((Settings.BillboardDeathStumbleAwayBeforeExplosionDistance > 0.0) &&
				Game::Mio.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.BillboardDeathStumbleAwayBeforeExplosionDistance + 100.0) &&
				!Game::Mio.IsPlayerDead())
			{
				// Stumble away from the pending explosion
				FVector Dir = (Game::Mio.ActorLocation - Owner.ActorLocation).VectorPlaneProject(Game::Mio.ActorUpVector).GetSafeNormal();
				Game::Mio.ApplyStumble(Dir * Settings.BillboardDeathStumbleAwayBeforeExplosionDistance, Settings.BillboardDeathStumbleAwayBeforeExplosionDuration);
			}
		}
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Owner.RemoveActorDisable(this);
		
		if (bIsDying)
		{
			Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
			BladeOutline.UnblockOutline(this);
		}

		bIsDying = false;
		bRemoteFinishedDying = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnRemotePreDeath()
	{
		if (HasControl())
			return; // Remote side only

		RemoteDeathTime = Time::GameTimeSeconds;
		UBasicAIDamageEffectHandler::Trigger_OnDeath(Owner);
	}
};
