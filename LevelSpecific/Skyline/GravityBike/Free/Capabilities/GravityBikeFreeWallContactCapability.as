/**
 * FB TODO: Is this capability even needed anymore after we added wall reflects?
 */
class UGravityBikeFreeWallContactCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);

	default TickGroup = EHazeTickGroup::LastMovement;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.HasWallContact())
			return false;

		const FVector Velocity = MoveComp.Velocity;
		if(Velocity.IsNearlyZero())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MoveComp.HasWallContact())
			return true;

		const FVector Velocity = MoveComp.Velocity;
		if(Velocity.IsNearlyZero())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FGravityBikeFreeOnWallImpactEventData EventData;
		EventData.ImpactPoint = MoveComp.WallContact.ImpactPoint.PointPlaneProject(GravityBike.MeshPivot.WorldLocation, GravityBike.ActorUpVector);
		FVector Normal = Math::Lerp(-GravityBike.ActorVelocity, MoveComp.WallContact.ImpactNormal, 0.3);
		EventData.ImpactNormal = Normal;
		EventData.ImpactStrength = Math::Abs(MoveComp.Velocity.DotProduct(Normal));
		UGravityBikeFreeEventHandler::Trigger_OnWallImpact(GravityBike, EventData);
	}
};