// copied mostly from PerchSplineAirMovementCapability
class ULightSeekerPlayerAssistedAirMoveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	// default CapabilityTags.Add(PlayerMovementTags::Perch);
	// default CapabilityTags.Add(PlayerPerchPointTags::PerchPointSpline);

	//default CapabilityTags.Add(PlayerMovementExclusionTags::ExcludePerch);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;
	default TickGroupSubPlacement = 5;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	ULightSeekerPlayerAssistedAirMoveComponent AssistComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerFloorMotionComponent FloorMotionComp;

	float VerticalDistanceToSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		AssistComp = ULightSeekerPlayerAssistedAirMoveComponent::GetOrCreate(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (AssistComp.AllSeekersAreSleeping())
			return false;

		if (!MoveComp.IsInAir())
			return false;

		FVector SplineLocation = AssistComp.GetClosestPointOnLightSeekers();
		FVector ToSpline = SplineLocation - Player.ActorLocation;
		if (ToSpline.Size() > AssistComp.AssistingRange)
			return false;

		if (ToSpline.DotProduct(MoveComp.GetWorldUp()) > 0) 
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (AssistComp.AllSeekersAreSleeping())
			return true;

		if (!MoveComp.IsInAir())
			return true;

		FVector SplineLocation = AssistComp.GetClosestPointOnLightSeekers();
		FVector ToSpline = SplineLocation - Player.ActorLocation;
		if (ToSpline.Size() > AssistComp.AssistingRange)
			return true;

		if (ToSpline.DotProduct(MoveComp.GetWorldUp()) > 0) 
			return true;

		if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) <= 0.0)
		{
			// if (AssistComp.Data.State != EPlayerPerchState::PerchingOnSpline)
			// 	return true;

			if (VerticalDistanceToSpline < 5.0)
				return true;
		}

		return false;
	}
};