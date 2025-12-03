
class UPlayerSwingImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingImpact);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 18;
	default TickGroupSubPlacement = 22;	

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;	
	UPlayerSwingComponent SwingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		SwingComp = UPlayerSwingComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MoveComp.HasWallContact())
			return false;

		if (!SwingComp.Data.HasValidSwingPoint())
			return false;

		if (SwingComp.Data.HasValidWall())
			return false;
		
		FVector FlattenedVelocity = MoveComp.GetLastRequestedVelocityWithoutImpulse().ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		float AngleDifference = Math::RadiansToDegrees(MoveComp.WallContact.ImpactNormal.AngularDistance(-FlattenedVelocity));
		if (AngleDifference > 45.0)
			return false;

		if (DeactiveDuration < 1.0)
			return false;

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
		FVector Velocity = MoveComp.GetLastRequestedVelocityWithoutImpulse();

		const float WorldUpDot = MoveComp.WorldUp.DotProduct(Velocity);
		Velocity -= MoveComp.WorldUp * WorldUpDot * 1.0;

		FVector FlattenedNormal = MoveComp.WallContact.Normal.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		const float NormalDot = FlattenedNormal.DotProduct(Velocity);
		Velocity -= FlattenedNormal * NormalDot * 1.0;

		Velocity += Velocity.GetSafeNormal() * (WorldUpDot + Math::Abs(NormalDot)) * 0.1;
		Velocity -= MoveComp.WorldUp * WorldUpDot * 0.2;
		Velocity -= FlattenedNormal * NormalDot * 0.2;

		Player.SetActorVelocity(Velocity);

		FVector ImpactDirection = Player.ActorRotation.UnrotateVector(-FlattenedNormal);
		SwingComp.AnimData.ImpactDirection = FVector2D(ImpactDirection.X, ImpactDirection.Y);
		SwingComp.AnimData.bImpacted = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwingComp.AnimData.bImpacted = false;		
	}
}