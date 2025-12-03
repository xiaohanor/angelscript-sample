
struct FTeenDragonTailRollAttackParams
{
	FVector AreaLocation;
	float AreaRadius;
	TArray<UTeenDragonTailAttackResponseComponent> HitComponents;
};

class UTeenDragonTailRollAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"TeenDragon");
	default CapabilityTags.Add(n"RollAttack");

	default DebugCategory = n"TeenDragon";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;

	//ATeenDragon TeenDragon;
	//AHazePlayerCharacter Player;
	UPlayerTailTeenDragonComponent DragonComp;
	UHazeMovementComponent MoveComp;

	USteppingMovementData Movement;

	bool bHitTriggered = false;
	FTeenDragonTailRollAttackParams AttackParams;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		//TeenDragon = Cast<ATeenDragon>(Owner);
		//Player = TeenDragon.Player;
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonTailRollAttackParams& Params) const
	{
		return false;

		// if (!DragonComp.bIsRolling)
		// 	return false;
		// if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
		// 	return false;

		// FHazeTraceSettings Trace;
		// Trace.UseSphereShape(TeenDragonTailRollAttack::DamageRadius);
		// Trace.TraceWithChannel(ECollisionChannel::WeaponTraceZoe);
		// Trace.IgnorePlayers();

		// FOverlapResultArray OverlapHits = Trace.QueryOverlaps(TeenDragon.ActorLocation);
		// for (FOverlapResult Overlap : OverlapHits)
		// {
		// 	if (Overlap.Actor == nullptr)
		// 		continue;

		// 	auto ResponseComp = UTeenDragonTailAttackResponseComponent::Get(Overlap.Actor);
		// 	if (ResponseComp != nullptr)
		// 		Params.HitComponents.Add(ResponseComp);
		// }

		// Params.AreaLocation = TeenDragon.ActorLocation;
		// Params.AreaRadius = TeenDragonTailRollAttack::DamageRadius;
		// return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > TeenDragonTailRollAttack::AttackWindup + TeenDragonTailRollAttack::AttackBackswing)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonTailRollAttackParams Params)
	{
		Player.BlockCapabilities(n"GameplayAction", this);
		Player.BlockCapabilities(n"Movement", this);

		bHitTriggered = false;
		AttackParams = Params;
		DragonComp.AnimationState.Apply(ETeenDragonAnimationState::RollAreaAttack, this);

		Player.PlayCameraShake(DragonComp.RollAreaAttackCameraShake, this); 
		UTeenDragonTailRollAttackEventHandler::Trigger_RollAreaAttackStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"GameplayAction", this);
		Player.UnblockCapabilities(n"Movement", this);
		DragonComp.AnimationState.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bHitTriggered)
		{
			if (ActiveDuration > TeenDragonTailRollAttack::AttackWindup)
			{
				for (auto ResponseComp : AttackParams.HitComponents)
				{
					FRollAreaAttackParams ResponseParams;
					ResponseParams.AreaCenterLocation = AttackParams.AreaLocation;
					ResponseParams.AreaRadius = AttackParams.AreaRadius;
					ResponseParams.PlayerInstigator = Player;
					ResponseParams.DamageDealt = TeenDragonTailRollAttack::AttackDamage;
					ResponseComp.OnHitByRollAreaAttack.Broadcast(ResponseParams);

					FTeenDragonTailRollAttackImpactParams ImpactParams;
					ImpactParams.ImpactType = ResponseComp.ImpactType;
					ImpactParams.HitComponent = ResponseComp;
					ImpactParams.RollAreaCenter = AttackParams.AreaLocation;
					UTeenDragonTailRollAttackEventHandler::Trigger_RollAreaAttackImpact(Player, ImpactParams);
				}
				bHitTriggered = true;
			}
		}

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}
			// Remote
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(n"RollAttack");
		}
	}
}