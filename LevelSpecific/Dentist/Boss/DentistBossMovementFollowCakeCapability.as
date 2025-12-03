namespace DentistBossCapabilityTags
{
	const FName DentistMovementFollowCake = n"DentistMovementFollowCake";
};

/**
 * Put this on all actors that should follow the cake in the Dentist Boss
 */
class UDentistBossMovementFollowCakeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(DentistBossCapabilityTags::DentistMovementFollowCake);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UHazeMovementComponent MoveComp;

	const float CakeRadiusMargin = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		const ADentistBossCake Cake = TListedActors<ADentistBossCake>().Single;
		if(Cake == nullptr)
			return false;

		const FVector RelativeLocation = Cake.ActorTransform.InverseTransformPositionNoScale(Owner.ActorLocation);
		if(RelativeLocation.Size2D(FVector::UpVector) > Cake.OuterRadius + CakeRadiusMargin)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		const ADentistBossCake Cake = TListedActors<ADentistBossCake>().Single;
		if(Cake == nullptr)
			return true;

		const FVector RelativeLocation = Cake.ActorTransform.InverseTransformPositionNoScale(Owner.ActorLocation);
		if(RelativeLocation.Size2D(FVector::UpVector) > Cake.OuterRadius + CakeRadiusMargin)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		const ADentistBossCake Cake = TListedActors<ADentistBossCake>().Single;
		MoveComp.FollowComponentMovement(Cake.Root, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Low);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::Release);
	}
};