event void FIslandNecromancerReviveTargetOnReviveSignature();

class UIslandNecromancerReviveTargetComponent : UActorComponent
{
	AHazeActor HazeOwner;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIHealthComponent HealthComp;

	bool bEnabled;

	FIslandNecromancerReviveTargetOnReviveSignature OnRevive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.JoinTeam(IslandNecromancerTags::IslandNecromancerReviveTargetTeam);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	bool IsRevivable()
	{
		auto Team = HazeTeam::GetTeam(IslandNecromancerTags::IslandNecromancerTeam);
		if(HealthComp.IsAlive())
			return false;
		if(!MoveComp.IsOnWalkableGround())
			return false;
		if(Team == nullptr || Team.GetMembers().Num() == 0)
			return false;

		bool CanRevive = false;
		for(AActor Member: Team.GetMembers())
		{
			if (Member == nullptr)
				continue;
			auto MemberHealthComp = UBasicAIHealthComponent::Get(Member);
			if(MemberHealthComp == nullptr || MemberHealthComp.IsDead())
				continue;
			CanRevive = true;
			break;
		}
		if(!CanRevive)
			return false;
		
		return true;
	}

	void Revive()
	{
		OnRevive.Broadcast();
	}
}