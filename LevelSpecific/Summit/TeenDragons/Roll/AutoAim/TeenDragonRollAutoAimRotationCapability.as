class UTeenDragonRollAutoAimRotationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	UPlayerTargetablesComponent PlayerTargetablesComp;
	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		RollComp = UTeenDragonRollComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!RollComp.IsRolling())
			return false;

		if(RollComp.bIsHomingTowardsTarget)
			return false;

		auto PrimaryTarget = PlayerTargetablesComp.GetPrimaryTarget(UTeenDragonRollAutoAimComponent);

		if(PrimaryTarget == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!RollComp.IsRolling())
			return true;

		if(RollComp.bIsHomingTowardsTarget)
			return true;

		auto PrimaryTarget = PlayerTargetablesComp.GetPrimaryTarget(UTeenDragonRollAutoAimComponent);

		if(PrimaryTarget == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RollComp.bSteeringIsOverridenByAutoAim = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RollComp.bSteeringIsOverridenByAutoAim = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UTeenDragonRollAutoAimComponent Target;

		auto PrimaryTarget = PlayerTargetablesComp.GetPrimaryTarget(UTeenDragonRollAutoAimComponent);
		if(PrimaryTarget == nullptr)
			return;
		
		Target = Cast<UTeenDragonRollAutoAimComponent>(PrimaryTarget);

		FVector TowardsCenter = (Target.WorldLocation - Player.ActorLocation).VectorPlaneProject(Player.MovementWorldUp);
		FQuat RotToCenter = FQuat::MakeFromXZ(TowardsCenter, FVector::UpVector);

		FQuat CurrentRotation = Player.ActorRotation.Quaternion();

		FQuat InfluencedRotation = Math::QInterpTo(CurrentRotation, RotToCenter, DeltaTime, Target.InterpSpeed);
		Player.SetActorRotation(InfluencedRotation);
	}
}