
class UIslandWalkerLegAttackBehaviour : UBasicBehaviour
{
	UIslandWalkerSettings Settings;
	UIslandWalkerLegsComponent LegsComp;
	TArray<FIslandWalkerLegAttackData> Attacks;
	AHazeCharacter Character;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AHazeCharacter>(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		LegsComp = UIslandWalkerLegsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Attacks.Empty();
		for(AIslandWalkerLegTarget Target: LegsComp.LegTargets)
		{
			FIslandWalkerLegAttackData Data;			
			Data.PositionComp = Target.CenterComponent;
			Attacks.Add(Data);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(FIslandWalkerLegAttackData& Attack: Attacks)
		{
			FVector TargetLocation = Attack.PositionComp.WorldLocation;
			TargetLocation.Z -= 75;
			if(Math::Abs(TargetLocation.Z - Owner.ActorLocation.Z) > 125)
			{
				Attack.bAttack = true;
			}
			else if(Attack.bAttack)
			{
				UIslandWalkerEffectHandler::Trigger_OnLegAttack(Owner, FIslandWalkerLegAttackEventData(TargetLocation));
				for(AHazePlayerCharacter Player: Game::Players)
				{
					if(Player.ActorLocation.IsWithinDist(TargetLocation, 200))
					{
						FKnockdown Knockdown;
						Knockdown.Duration = 0.75;
						FVector Dir = (Player.ActorLocation - TargetLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
						Dir.Z = 0.75;
						Knockdown.Move = Dir * 450;
						Player.ApplyKnockdown(Knockdown);
						Player.DealTypedDamage(Owner, 0.2, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);
						UPlayerDamageEventHandler::Trigger_TakeBigDamage(Player);
					}
				}
				Attack.bAttack = false;
			}
		}
	}
}

struct FIslandWalkerLegAttackData
{
	USceneComponent PositionComp;
	bool bAttack;
}