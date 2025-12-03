class USkylineRappellerRopeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"RappellingRope");
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UCableComponent CableComp;
	USkylineRappellerRopeCollisionComponent RopeCollision;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineRappellerComponent RappellerComp;
	FVector AnchorOffset;
	FVector AnchorLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CableComp = UCableComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		RappellerComp = USkylineRappellerComponent::GetOrCreate(Owner);
		RopeCollision = USkylineRappellerRopeCollisionComponent::Get(Owner);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnPostRespawn.AddUFunction(this, n"OnPostReset");
		AnchorOffset = CableComp.EndLocation;
		SetAnchor();
	}

	UFUNCTION()
	private void OnPostReset()
	{
		SetAnchor();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (RopeCollision.bIsCut)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RopeCollision.bIsCut)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(RappellerComp.AnchorComponent != nullptr)
		{
			AnchorLocation = RappellerComp.AnchorComponent.WorldTransform.TransformPosition(RappellerComp.AnchorOffset);
		}

		// Rope end should stay fixed to anchor location 
		CableComp.EndLocation = Owner.ActorTransform.InverseTransformPosition(AnchorLocation);		
	}

	void SetAnchor()
	{
		TArray<USceneComponent> FollowedComponents;
		MoveComp.GetFollowedComponents(FollowedComponents);
		if(FollowedComponents.Num() > 0)
		{
			RappellerComp.AnchorComponent = FollowedComponents[0];
			RappellerComp.AnchorOffset = RappellerComp.AnchorComponent.WorldTransform.InverseTransformPosition(Owner.ActorTransform.TransformPosition(AnchorOffset));
			return;
		}

		RappellerComp.AnchorComponent = nullptr;
		AnchorLocation = Owner.ActorTransform.TransformPosition(AnchorOffset);
	}
}