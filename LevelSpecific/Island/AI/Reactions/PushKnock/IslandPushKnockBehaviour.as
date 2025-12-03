class UIslandPushKnockBehaviour : UBasicBehaviour
{
	ABasicAICharacter OwnerCharacter;
	UIslandPushKnockComponent KnockComp;
	TArray<AHazeCharacter> KnockedCharacters;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		OwnerCharacter = Cast<ABasicAICharacter>(Owner);
		KnockComp = UIslandPushKnockComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!KnockComp.bTriggerImpacts)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!KnockComp.bTriggerImpacts)
			return true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		KnockedCharacters.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Team = HazeTeam::GetTeam(PushKnockTags::PushKnockTargetsTeam);

		for(AHazeActor Member: Team.GetMembers())
		{
			AHazeCharacter Character = Cast<AHazeCharacter>(Member);
			if(Character == nullptr || KnockedCharacters.Contains(Character) || Character == OwnerCharacter) 
				continue;

			FTransform CharacterTransform = Character.ActorTransform;
			CharacterTransform.Location = Character.ActorCenterLocation;

			FTransform OwnerTransform = OwnerCharacter.ActorTransform;
			OwnerTransform.Location = OwnerCharacter.ActorCenterLocation;

			if(Overlap::QueryShapeOverlap(Character.CapsuleComponent.GetCollisionShape(), CharacterTransform, OwnerCharacter.CapsuleComponent.GetCollisionShape(), OwnerTransform))
			{
				auto ImpactSelf = UIslandPushKnockSelfImpactResponseComponent::Get(Owner);
				if(ImpactSelf != nullptr)
				{
					ImpactSelf.OnImpact.Broadcast(OwnerCharacter);
				}
				
				auto ImpactTarget = UIslandPushKnockTargetImpactResponseComponent::Get(Character);
				if(ImpactTarget != nullptr)
				{
					ImpactTarget.OnImpact.Broadcast(OwnerCharacter);
				}

				KnockedCharacters.Add(Character);
			}	
		}
	}
}